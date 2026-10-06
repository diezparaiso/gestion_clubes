[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

foreach ($name in @('SUPABASE_URL', 'SUPABASE_ANON_KEY')) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
        throw "Falta la variable de entorno requerida: $name"
    }
}

$script:BaseUrl = $env:SUPABASE_URL.TrimEnd('/')
$script:AnonKey = $env:SUPABASE_ANON_KEY
$script:Cli = Join-Path (Get-Location) 'supabase_2.117.0-beta.18_windows_amd64\supabase.exe'
$script:Results = New-Object System.Collections.Generic.List[object]
$script:Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$script:QaUsers = New-Object System.Collections.Generic.List[string]
$script:Actors = @{}
$script:ClubA = $null
$script:ClubB = $null
$script:PublicRaffle = $null
$script:QaContent = @{}

function Add-Result {
    param(
        [string]$Id,
        [string]$Description,
        [string]$Expected,
        [string]$Actual,
        [bool]$Passed,
        [string]$State = 'PASS'
    )

    if ($State -eq 'PASS' -and -not $Passed) { $State = 'FAIL' }
    $row = [pscustomobject]@{
        Id = $Id
        Description = $Description
        Expected = $Expected
        Actual = $Actual
        State = $State
    }
    $script:Results.Add($row)
    $actualShort = $Actual -replace '[\r\n]+', ' '
    if ($actualShort.Length -gt 170) { $actualShort = $actualShort.Substring(0, 167) + '...' }
    Write-Host "[$State] $Id | esperado=$Expected | obtenido=$actualShort"
}

function New-RandomPassword {
    $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%^&*()-_=+'
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    $result = New-Object System.Text.StringBuilder
    foreach ($byte in $bytes) {
        [void]$result.Append($chars[[int]$byte % $chars.Length])
    }
    return $result.ToString()
}

function Convert-ResponseBody {
    param([string]$Content)
    if ([string]::IsNullOrWhiteSpace($Content)) { return $null }
    try { return ($Content | ConvertFrom-Json -ErrorAction Stop) } catch { return $Content }
}

function Invoke-QaRequest {
    param(
        [ValidateSet('GET', 'POST', 'PATCH', 'DELETE', 'PUT')]
        [string]$Method,
        [string]$Path,
        [string]$Token = $script:AnonKey,
        $Body = $null,
        [hashtable]$ExtraHeaders = @{}
    )

    $headers = @{
        apikey = $script:AnonKey
        Authorization = "Bearer $Token"
        Accept = 'application/json'
    }
    foreach ($key in $ExtraHeaders.Keys) { $headers[$key] = $ExtraHeaders[$key] }
    $uri = if ($Path.StartsWith('http')) { $Path } else { "$($script:BaseUrl)$Path" }
    $rawBody = $null
    if ($null -ne $Body) {
        $headers['Content-Type'] = 'application/json'
        $rawBody = ConvertTo-Json -InputObject $Body -Depth 20 -Compress
    }
    try {
        $response = Invoke-WebRequest -Uri $uri -Method $Method -Headers $headers -Body $rawBody -UseBasicParsing
        $content = [string]$response.Content
        return [pscustomobject]@{
            Status = [int]$response.StatusCode
            Content = $content
            Json = (Convert-ResponseBody $content)
        }
    } catch {
        $status = 0
        $content = ''
        if ($_.Exception.Response) {
            try { $status = [int]$_.Exception.Response.StatusCode } catch {}
            try {
                $stream = $_.Exception.Response.GetResponseStream()
                if ($stream) {
                    $reader = New-Object System.IO.StreamReader($stream)
                    try { $content = $reader.ReadToEnd() } finally { $reader.Dispose() }
                }
            } catch {}
        }
        if ([string]::IsNullOrWhiteSpace($content) -and $_.ErrorDetails) {
            $content = [string]$_.ErrorDetails.Message
        }
        return [pscustomobject]@{
            Status = $status
            Content = $content
            Json = (Convert-ResponseBody $content)
        }
    }
}

function Get-Message {
    param($Response)
    if ($null -eq $Response.Json) { return 'sin cuerpo' }
    if ($Response.Json -is [string]) { return $Response.Json }
    if ($Response.Json -is [System.Array]) { return "array($($Response.Json.Count))" }
    if ($Response.Json.PSObject.Properties['message']) { return [string]$Response.Json.message }
    if ($Response.Json.PSObject.Properties['error']) { return [string]$Response.Json.error }
    return ($Response.Json | ConvertTo-Json -Depth 4 -Compress)
}

function Get-FirstJsonObject {
    param([string]$Text)
    $start = $Text.IndexOf('{')
    if ($start -lt 0) { return $null }
    $depth = 0
    $inString = $false
    $escaped = $false
    for ($index = $start; $index -lt $Text.Length; $index++) {
        $character = $Text[$index]
        if ($inString) {
            if ($escaped) { $escaped = $false; continue }
            if ($character -eq '\') { $escaped = $true; continue }
            if ($character -eq '"') { $inString = $false }
            continue
        }
        if ($character -eq '"') { $inString = $true; continue }
        if ($character -eq '{') { $depth++ }
        if ($character -eq '}') {
            $depth--
            if ($depth -eq 0) { return $Text.Substring($start, $index - $start + 1) }
        }
    }
    return $null
}

function Get-RemoteSignatures {
    if (-not (Test-Path -LiteralPath $script:Cli)) { throw "No se encuentra Supabase CLI: $script:Cli" }
    $sql = @"
select p.proname, pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = any(array[
    'create_club', 'change_member_role', 'revoke_member_access',
    'clear_must_change_password', 'mark_notification_delivery_read',
    'get_public_club', 'get_public_events', 'get_public_posts',
    'get_public_sponsors', 'get_public_raffle_numbers',
    'reserve_public_raffle_numbers', 'set_raffle_manual_winner',
    'draw_raffle_random_secure', 'draw_raffle_random', 'record_raffle_payment',
    'create_sponsor', 'is_club_manager', 'has_club_permission',
    'has_public_active_raffle'
  ])
order by p.proname;
"@
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $script:Cli db query --linked $sql 2>&1 | Out-String
    $cliExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousPreference
    if ($cliExitCode -ne 0) { throw 'No fue posible consultar firmas remotas con db query --linked.' }
    $json = Get-FirstJsonObject $output
    if (-not $json) { throw 'La consulta de firmas no devolvió JSON parseable.' }
    $payload = $json | ConvertFrom-Json
    $map = @{}
    foreach ($item in $payload.rows) { $map[[string]$item.proname] = ([string]$item.args -replace '\s+', ' ').Trim() }
    return $map
}

$script:RemoteSignatures = Get-RemoteSignatures
$script:ExpectedSignatures = @{
    create_club = 'club_public_name text, club_legal_name text, club_slug text'
    change_member_role = 'p_club_id uuid, p_profile_id uuid, p_role club_role'
    revoke_member_access = 'p_club_id uuid, p_profile_id uuid'
    clear_must_change_password = ''
    mark_notification_delivery_read = 'p_delivery_id uuid'
    get_public_club = 'target_club_slug text'
    get_public_events = 'target_club_slug text'
    get_public_posts = 'target_club_slug text'
    get_public_sponsors = 'target_club_slug text'
    get_public_raffle_numbers = 'target_club_slug text, target_raffle_slug text'
    reserve_public_raffle_numbers = 'target_club_slug text, target_raffle_slug text, selected_numbers integer[], target_buyer_name text, target_buyer_email text, target_buyer_phone text'
    set_raffle_manual_winner = 'target_raffle_id uuid, target_winning_number integer'
    draw_raffle_random_secure = 'target_raffle_id uuid'
    draw_raffle_random = 'target_raffle_id uuid'
    record_raffle_payment = 'target_ticket_id uuid, target_profile_id uuid, target_payment_reference text'
    create_sponsor = 'p_club_id uuid, p_name text, p_website text, p_contact_email citext, p_contact_phone text, p_contract_start_date date, p_contract_end_date date, p_annual_amount numeric, p_benefits text, p_is_public boolean'
    is_club_manager = 'target_club_id uuid'
    has_club_permission = 'target_club_id uuid, target_permission club_permission'
    has_public_active_raffle = 'target_club_id uuid'
}

function Assert-RpcSignature {
    param([string]$Name)
    if (-not $script:ExpectedSignatures.ContainsKey($Name)) {
        throw "No se registró la firma esperada para RPC $Name."
    }
    if (-not $script:RemoteSignatures.ContainsKey($Name)) {
        throw "RPC $Name no existe en el catálogo remoto; no se enviará la llamada."
    }
    $actual = $script:RemoteSignatures[$Name]
    $expected = $script:ExpectedSignatures[$Name]
    if ($actual -ne $expected) {
        throw "Firma remota inesperada para $Name (se omite la llamada)."
    }
}

function Invoke-Rpc {
    param([string]$Name, [hashtable]$Params, [string]$Token = $script:AnonKey)
    Assert-RpcSignature $Name
    return Invoke-QaRequest -Method POST -Path "/rest/v1/rpc/$Name" -Token $Token -Body $Params
}

function New-AuthUser {
    param([string]$Label, [string]$Password)
    $email = "qa-$($script:Timestamp)-$Label@example.com"
    $response = Invoke-QaRequest -Method POST -Path '/auth/v1/signup' -Body @{ email = $email; password = $Password }
    if ($response.Status -lt 200 -or $response.Status -ge 300 -or -not $response.Json.access_token) {
        throw "Signup fallido ($($response.Status)): $(Get-Message $response)"
    }
    $script:QaUsers.Add($email)
    return @{
        Email = $email
        Password = $Password
        Token = [string]$response.Json.access_token
        Id = [string]$response.Json.user.id
        Role = 'club_president'
    }
}

function New-Club {
    param($President, [string]$Suffix)
    $slug = "qa-club-$Suffix-$($script:Timestamp)"
    $response = Invoke-Rpc -Name create_club -Token $President.Token -Params @{
        club_public_name = "qa-club-$Suffix-$($script:Timestamp)"
        club_legal_name = "qa-club-$Suffix-$($script:Timestamp)"
        club_slug = $slug
    }
    if ($response.Status -lt 200 -or $response.Status -ge 300) {
        throw "create_club fallido ($($response.Status)): $(Get-Message $response)"
    }
    $club = $response.Json
    if ($club -is [array]) { $club = $club[0] }
    return @{ Id = [string]$club.id; Slug = $slug; President = $President }
}

function New-ManagedActor {
    param($President, $Club, [string]$Role)
    $label = $Role.Replace('club_', '').Replace('_', '-')
    $password = New-RandomPassword
    $email = "qa-$($script:Timestamp)-$label@example.com"
    $body = @{
        clubId = $Club.Id
        email = $email
        password = $password
        role = $Role
        firstName = "QA $label"
        lastName = $script:Timestamp
    }
    $response = Invoke-QaRequest -Method POST -Path '/functions/v1/manage-club-user' -Token $President.Token -Body $body
    if ($response.Status -lt 200 -or $response.Status -ge 300) {
        throw "manage-club-user fallido ($($response.Status)) para $Role`: $(Get-Message $response)"
    }
    $bodyText = [string]$response.Content
    if ($bodyText.Contains($password)) { throw "La función devolvió la contraseña para el rol $Role." }
    $script:QaUsers.Add($email)
    $login = Invoke-QaRequest -Method POST -Path '/auth/v1/token?grant_type=password' -Body @{ email = $email; password = $password }
    if ($login.Status -lt 200 -or $login.Status -ge 300 -or -not $login.Json.access_token) {
        throw "Login de cuenta creada fallido ($($login.Status)) para $Role`: $(Get-Message $login)"
    }
    return @{
        Email = $email
        Password = $password
        Token = [string]$login.Json.access_token
        Id = [string]$login.Json.user.id
        Role = $Role
        Club = $Club
    }
}

function Get-RestRows {
    param([string]$Table, [string]$Query, [string]$Token)
    return Invoke-QaRequest -Method GET -Path "/rest/v1/$Table`?$Query" -Token $Token
}

function Get-RowCount {
    param($Response)
    if ($Response.Status -lt 200 -or $Response.Status -ge 300) { return -1 }
    if ($Response.Json -is [array]) { return $Response.Json.Count }
    if ($null -eq $Response.Json) { return 0 }
    return 1
}

function Get-FirstRow {
    param($Value)
    if ($Value -is [array]) {
        if ($Value.Count -gt 0) { return $Value[0] }
        return $null
    }
    return $Value
}

function Normalize-Text {
    param([string]$Value)
    $normalized = $Value.Normalize([System.Text.NormalizationForm]::FormD)
    return [regex]::Replace($normalized, '\p{Mn}', '').ToLowerInvariant()
}

function Add-SetupResult {
    param([string]$Id, [string]$Description, $Response)
    $ok = $Response.Status -ge 200 -and $Response.Status -lt 300
    Add-Result -Id $Id -Description $Description -Expected 'HTTP 2xx' -Actual "HTTP $($Response.Status): $(Get-Message $Response)" -Passed $ok
}

function Invoke-ReadMatrix {
    param($Actor, [string]$ClubId, [string]$Label)
    $tables = @(
        @{ Name='memberships'; Domain='members'; Read=$Label -in @('president','secretary') }
        @{ Name='club_memberships'; Domain='access'; Read=$true }
        @{ Name='financial_accounts'; Domain='finance'; Read=$Label -in @('president','treasurer') }
        @{ Name='financial_transactions'; Domain='finance'; Read=$Label -in @('president','treasurer') }
        @{ Name='seasons'; Domain='teams'; Read=$Label -in @('president','coach') }
        @{ Name='teams'; Domain='teams'; Read=$Label -in @('president','coach') }
        @{ Name='players'; Domain='players'; Read=$Label -in @('president','coach') }
        @{ Name='team_players'; Domain='players'; Read=$Label -in @('president','coach') }
        @{ Name='raffles'; Domain='raffles'; Read=$Label -eq 'president' }
        @{ Name='raffle_tickets'; Domain='raffles'; Read=$Label -eq 'president' }
        @{ Name='sponsors'; Domain='sponsors'; Read=$Label -eq 'president' }
        @{ Name='posts'; Domain='news'; Read=$Label -in @('president','secretary') }
        @{ Name='events'; Domain='events'; Read=$Label -in @('president','secretary') }
        @{ Name='notifications'; Domain='notifications'; Read=$Label -in @('president','treasurer','secretary','coach') }
    )
    foreach ($entry in $tables) {
        $fixtureAvailable = $true
        if ($entry.Name -eq 'sponsors') {
            $fixtureAvailable = -not [string]::IsNullOrWhiteSpace([string]$script:QaContent.SponsorId)
        }
        if ($entry.Name -eq 'notifications') {
            $fixtureAvailable = [bool]($script:QaContent['Notification-all_members'] -or $script:QaContent['Notification-managers'])
        }
        if (-not $fixtureAvailable) {
            Add-Result -Id "ROLE-$Label-$($entry.Domain)-$($entry.Name)" -Description "$Label consulta $($entry.Name) en su club" -Expected 'fixture QA para verificar la lectura' -Actual 'NO EJECUTADO: fixture no disponible por fallo de creación previo' -Passed $false -State 'BLOQUEADO'
            continue
        }
        $response = Get-RestRows -Table $entry.Name -Query "select=id,club_id&club_id=eq.$ClubId" -Token $Actor.Token
        $count = Get-RowCount $response
        $okRead = $response.Status -ge 200 -and $response.Status -lt 300 -and $count -gt 0
        $actual = if ($response.Status -ge 200 -and $response.Status -lt 300) { "HTTP $($response.Status), filas=$count" } else { "HTTP $($response.Status): $(Get-Message $response)" }
        $passed = if ($entry.Read) { $okRead } else { $response.Status -ge 200 -and $response.Status -lt 300 -and $count -eq 0 }
        $expected = if ($entry.Read) { 'lectura permitida, una o más filas QA' } else { 'cero filas o denegación' }
        Add-Result -Id "ROLE-$Label-$($entry.Domain)-$($entry.Name)" -Description "$Label consulta $($entry.Name) en su club" -Expected $expected -Actual $actual -Passed $passed
    }
}

function New-ClubFixtures {
    param($President, $Club, [string]$Label, [int]$MemberNumber)
    $fixture = @{}
    $season = Invoke-QaRequest -Method POST -Path '/rest/v1/seasons?select=id' -Token $President.Token -Body @{
        club_id = $Club.Id
        name = "qa-season-$Label-$($script:Timestamp)"
        start_date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')
        end_date = (Get-Date).AddYears(1).ToString('yyyy-MM-dd')
        is_current = $true
    } -ExtraHeaders @{ Prefer='return=representation' }
    Add-SetupResult -Id "SEED-$Label-SEASON" -Description "Temporada QA club $Label" -Response $season
    if ($season.Status -lt 200 -or $season.Status -ge 300) { return $fixture }
    $seasonRow = Get-FirstRow $season.Json
    $fixture.SeasonId = [string]$seasonRow.id

    $team = Invoke-QaRequest -Method POST -Path '/rest/v1/teams?select=id' -Token $President.Token -Body @{
        club_id = $Club.Id; name = "qa-team-$Label-$($script:Timestamp)"
        category = 'qa'; season_id = $seasonRow.id
    } -ExtraHeaders @{ Prefer='return=representation' }
    Add-SetupResult -Id "SEED-$Label-TEAM" -Description "Equipo QA club $Label" -Response $team
    if ($team.Status -ge 200 -and $team.Status -lt 300) {
        $teamRow = Get-FirstRow $team.Json
        $fixture.TeamId = [string]$teamRow.id
    }
    $player = Invoke-QaRequest -Method POST -Path '/rest/v1/players?select=id' -Token $President.Token -Body @{
        club_id = $Club.Id; profile_id = $President.Id
    } -ExtraHeaders @{ Prefer='return=representation' }
    Add-SetupResult -Id "SEED-$Label-PLAYER" -Description "Jugador QA club $Label" -Response $player
    if ($player.Status -ge 200 -and $player.Status -lt 300) {
        $playerRow = Get-FirstRow $player.Json
        $fixture.PlayerId = [string]$playerRow.id
        if ($fixture.TeamId) {
            $relation = Invoke-QaRequest -Method POST -Path '/rest/v1/team_players' -Token $President.Token -Body @{
                club_id = $Club.Id; team_id = $fixture.TeamId; player_id = $fixture.PlayerId
            } -ExtraHeaders @{ Prefer='return=representation' }
            Add-SetupResult -Id "SEED-$Label-TEAM-PLAYER" -Description "Relacion QA equipo/jugador club $Label" -Response $relation
            if ($relation.Status -ge 200 -and $relation.Status -lt 300) {
                $fixture.TeamPlayerId = [string](Get-FirstRow $relation.Json).id
            }
        }
    }
    $membership = Invoke-QaRequest -Method POST -Path '/rest/v1/memberships?select=id' -Token $President.Token -Body @{
        club_id = $Club.Id
        profile_id = $President.Id
        member_number = $MemberNumber
        membership_type = 'standard'
        status = 'active'
    } -ExtraHeaders @{ Prefer='return=representation' }
    Add-SetupResult -Id "SEED-$Label-MEMBERSHIP" -Description "Socio QA club $Label" -Response $membership
    if ($membership.Status -ge 200 -and $membership.Status -lt 300) {
        $fixture.MembershipId = [string](Get-FirstRow $membership.Json).id
    }
    $post = Invoke-QaRequest -Method POST -Path '/rest/v1/posts?select=id' -Token $President.Token -Body @{
        club_id = $Club.Id; title = "qa-draft-$Label-$($script:Timestamp)"
        body = 'QA draft only'; author_id = $President.Id; status = 'draft'
    } -ExtraHeaders @{ Prefer='return=representation' }
    Add-SetupResult -Id "SEED-$Label-POST" -Description "Noticia en borrador QA club $Label" -Response $post
    if ($post.Status -ge 200 -and $post.Status -lt 300) {
        $fixture.PostId = [string](Get-FirstRow $post.Json).id
    }
    $event = Invoke-QaRequest -Method POST -Path '/rest/v1/events?select=id' -Token $President.Token -Body @{
        club_id = $Club.Id; title = "qa-event-$Label-$($script:Timestamp)"
        description = 'QA private event'
        start_at = (Get-Date).AddDays(2).ToUniversalTime().ToString('o')
        end_at = (Get-Date).AddDays(2).AddHours(2).ToUniversalTime().ToString('o')
        created_by = $President.Id; visibility = 'club_only'
    } -ExtraHeaders @{ Prefer='return=representation' }
    Add-SetupResult -Id "SEED-$Label-EVENT" -Description "Evento privado QA club $Label" -Response $event
    if ($event.Status -ge 200 -and $event.Status -lt 300) {
        $fixture.EventId = [string](Get-FirstRow $event.Json).id
    }
    $raffleSlug = "qa-raffle-$Label-$($script:Timestamp)"
    $raffle = Invoke-QaRequest -Method POST -Path '/rest/v1/raffles?select=id' -Token $President.Token -Body @{
        club_id = $Club.Id; slug = $raffleSlug; title = "QA raffle $Label $($script:Timestamp)"
        description = 'QA only'; ticket_price = 1; total_numbers = 20
        start_at = (Get-Date).AddMinutes(-1).ToUniversalTime().ToString('o')
        end_at = (Get-Date).AddDays(2).ToUniversalTime().ToString('o')
        draw_at = (Get-Date).AddDays(3).ToUniversalTime().ToString('o')
        status = 'active'; raffle_type = 'sorteoPuro'; created_by = $President.Id
    } -ExtraHeaders @{ Prefer='return=representation' }
    Add-SetupResult -Id "SEED-$Label-RAFFLE" -Description "Rifa activa QA club $Label" -Response $raffle
    if ($raffle.Status -ge 200 -and $raffle.Status -lt 300) {
        $fixture.RaffleId = [string](Get-FirstRow $raffle.Json).id
    }
    return $fixture
}

function Get-DbQueryRows {
    param([string]$Sql)
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $script:Cli db query --linked $Sql 2>&1 | Out-String
    $cliExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousPreference
    if ($cliExitCode -ne 0) { throw 'db query --linked devolvió código distinto de cero.' }
    $json = Get-FirstJsonObject $output
    if (-not $json) { throw 'db query --linked no devolvió JSON.' }
    return (($json | ConvertFrom-Json).rows)
}

# Read-only live signature check comes first; every RPC call below is gated by it.
foreach ($functionName in $script:ExpectedSignatures.Keys) {
    $exists = $script:RemoteSignatures.ContainsKey($functionName)
    $matches = $exists -and $script:RemoteSignatures[$functionName] -eq $script:ExpectedSignatures[$functionName]
    $actual = if ($exists) { $script:RemoteSignatures[$functionName] } else { 'función ausente' }
    Add-Result -Id "SIG-$functionName" -Description "Firma leída en pg_proc antes de llamar $functionName" -Expected $script:ExpectedSignatures[$functionName] -Actual $actual -Passed $matches
}

try {
    $passwordA = New-RandomPassword
    $passwordB = New-RandomPassword
    $presidentA = New-AuthUser -Label 'president-a' -Password $passwordA
    $presidentA.Role = 'president'
    $presidentB = New-AuthUser -Label 'president-b' -Password $passwordB
    $presidentB.Role = 'president'
    $script:ClubA = New-Club -President $presidentA -Suffix 'a'
    $script:ClubB = New-Club -President $presidentB -Suffix 'b'
    $presidentA.Club = $script:ClubA
    $presidentB.Club = $script:ClubB
    $script:Actors['presidentA'] = $presidentA
    $script:Actors['presidentB'] = $presidentB
    Add-Result -Id 'SETUP-CLUBS' -Description 'Signup de dos presidentes y create_club de QA' -Expected '2 usuarios y 2 clubes qa-' -Actual "HTTP 2xx; clubs=$($script:ClubA.Id),$($script:ClubB.Id)" -Passed $true

    foreach ($role in @('club_treasurer','club_secretary','coach')) {
        $actor = New-ManagedActor -President $presidentA -Club $script:ClubA -Role $role
        $script:Actors[$role] = $actor
        Add-Result -Id "SETUP-$role" -Description 'Alta mediante manage-club-user; respuesta sin contraseña y login verificado' -Expected '200, solo success y token de login válido' -Actual "HTTP 200; contraseña no devuelta; login correcto; email=$($actor.Email)" -Passed $true
    }

    $badPassword = New-RandomPassword
    $invalidRoleEmail = "qa-$($script:Timestamp)-invalid-role@example.com"
    $invalidRoleResponse = Invoke-QaRequest -Method POST -Path '/functions/v1/manage-club-user' -Token $presidentA.Token -Body @{
        clubId = $script:ClubA.Id
        email = $invalidRoleEmail
        password = $badPassword
        role = 'club_president'
        firstName = 'QA Invalid'
        lastName = $script:Timestamp
    }
    Add-Result -Id 'ACCESS-ROLE-PRESIDENT-REJECT' -Description 'manage-club-user rechaza club_president' -Expected 'HTTP 400; cuenta no creada' -Actual "HTTP $($invalidRoleResponse.Status): $(Get-Message $invalidRoleResponse)" -Passed ($invalidRoleResponse.Status -eq 400)
    foreach ($nonPresident in @($script:Actors['club_treasurer'], $script:Actors['club_secretary'])) {
        $deniedAccess = Invoke-QaRequest -Method POST -Path '/functions/v1/manage-club-user' -Token $nonPresident.Token -Body @{
            clubId=$script:ClubA.Id; email="qa-$($script:Timestamp)-denied-access@example.com"
            password=(New-RandomPassword); role='staff'; firstName='QA'; lastName=$script:Timestamp
        }
        Add-Result -Id "ACCESS-MANAGE-DENIED-$($nonPresident.Role)" -Description "$($nonPresident.Role) intenta crear acceso de miembro" -Expected 'HTTP 403' -Actual "HTTP $($deniedAccess.Status): $(Get-Message $deniedAccess)" -Passed ($deniedAccess.Status -eq 403)
    }

    $roles = @{
        president = $presidentA
        treasurer = $script:Actors['club_treasurer']
        secretary = $script:Actors['club_secretary']
        coach = $script:Actors['coach']
    }
    $treasurer = $script:Actors['club_treasurer']

    $managerCheck = Invoke-Rpc -Name is_club_manager -Params @{ target_club_id=$script:ClubA.Id } -Token $presidentA.Token
    Add-Result -Id 'PERMISSION-PRESIDENT-MANAGER' -Description 'Presidente valida is_club_manager en el club recién creado' -Expected 'true' -Actual "HTTP $($managerCheck.Status): $(Get-Message $managerCheck)" -Passed ($managerCheck.Status -ge 200 -and $managerCheck.Status -lt 300 -and $managerCheck.Json -eq $true)
    $permissionsByRole = @{
        president = @('members_view','members_manage','finance_view','finance_manage','teams_view','teams_manage','players_view','players_manage','raffles_view','raffles_manage','news_view','news_manage','events_view','events_manage','notifications_view','access_manage','sponsors_manage')
        treasurer = @('finance_view','finance_manage','notifications_view')
        secretary = @('members_view','members_manage','news_view','news_manage','events_view','events_manage','notifications_view')
        coach = @('teams_view','players_view','notifications_view')
    }
    $permissionActors = @{
        president = $presidentA
        treasurer = $script:Actors['club_treasurer']
        secretary = $script:Actors['club_secretary']
        coach = $script:Actors['coach']
    }
    $allPermissions = @('members_view','members_manage','finance_view','finance_manage','teams_view','teams_manage','players_view','players_manage','raffles_view','raffles_manage','news_view','news_manage','events_view','events_manage','notifications_view','access_manage','sponsors_manage')
    foreach ($roleLabel in @('president','treasurer','secretary','coach')) {
        foreach ($permission in $allPermissions) {
            $expectedPermission = $permissionsByRole[$roleLabel] -contains $permission
            $permissionCheck = Invoke-Rpc -Name has_club_permission -Params @{
                target_club_id = $script:ClubA.Id
                target_permission = $permission
            } -Token $permissionActors[$roleLabel].Token
            $permissionValue = $permissionCheck.Json -eq $true
            Add-Result -Id "PERMISSION-$($roleLabel.ToUpperInvariant())-$permission" -Description "$roleLabel valida $permission con has_club_permission" -Expected ([string]$expectedPermission).ToLowerInvariant() -Actual "HTTP $($permissionCheck.Status): $(Get-Message $permissionCheck)" -Passed ($permissionCheck.Status -ge 200 -and $permissionCheck.Status -lt 300 -and $permissionValue -eq $expectedPermission)
        }
    }
    $season = Invoke-QaRequest -Method POST -Path '/rest/v1/seasons?select=id' -Token $presidentA.Token -Body @{
        club_id = $script:ClubA.Id
        name = "qa-season-$($script:Timestamp)"
        start_date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')
        end_date = (Get-Date).AddYears(1).ToString('yyyy-MM-dd')
        is_current = $true
    } -ExtraHeaders @{ Prefer='return=representation' }
    Add-SetupResult -Id 'SEED-SEASON' -Description 'Temporada QA para lectura de equipo/jugadores' -Response $season
    if ($season.Status -ge 200 -and $season.Status -lt 300 -and $season.Json) {
        $seasonRow = Get-FirstRow $season.Json
        $team = Invoke-QaRequest -Method POST -Path '/rest/v1/teams?select=id' -Token $presidentA.Token -Body @{
            club_id = $script:ClubA.Id
            name = "qa-team-$($script:Timestamp)"
            category = 'qa'
            season_id = $seasonRow.id
        } -ExtraHeaders @{ Prefer='return=representation' }
        Add-SetupResult -Id 'SEED-TEAM' -Description 'Equipo QA' -Response $team
        $player = Invoke-QaRequest -Method POST -Path '/rest/v1/players?select=id' -Token $presidentA.Token -Body @{
            club_id = $script:ClubA.Id
            profile_id = $presidentA.Id
        } -ExtraHeaders @{ Prefer='return=representation' }
        Add-SetupResult -Id 'SEED-PLAYER' -Description 'Jugador QA asociado al presidente QA' -Response $player
        if ($team.Status -ge 200 -and $team.Status -lt 300 -and $team.Json -and $player.Status -ge 200 -and $player.Status -lt 300 -and $player.Json) {
            $teamRow = Get-FirstRow $team.Json
            $playerRow = Get-FirstRow $player.Json
            $script:QaContent.TeamId = [string]$teamRow.id
            $script:QaContent.PlayerId = [string]$playerRow.id
            $relation = Invoke-QaRequest -Method POST -Path '/rest/v1/team_players' -Token $presidentA.Token -Body @{
                club_id = $script:ClubA.Id
                team_id = $teamRow.id
                player_id = $playerRow.id
            } -ExtraHeaders @{ Prefer='return=representation' }
            Add-SetupResult -Id 'SEED-TEAM-PLAYER' -Description 'Relación equipo-jugador QA' -Response $relation
            if ($relation.Status -ge 200 -and $relation.Status -lt 300 -and $relation.Json) {
                $script:QaContent.TeamPlayerId = [string](Get-FirstRow $relation.Json).id
            }
        }
    }

    $postDraft = Invoke-QaRequest -Method POST -Path '/rest/v1/posts?select=id' -Token $presidentA.Token -Body @{
        club_id = $script:ClubA.Id
        title = "qa-draft-$($script:Timestamp)"
        body = 'QA draft only'
        author_id = $presidentA.Id
        status = 'draft'
    } -ExtraHeaders @{ Prefer='return=representation' }
    Add-SetupResult -Id 'SEED-POST-DRAFT' -Description 'Noticia en borrador QA' -Response $postDraft
    if ($postDraft.Status -ge 200 -and $postDraft.Status -lt 300 -and $postDraft.Json) {
        $script:QaContent.PostDraftId = [string](Get-FirstRow $postDraft.Json).id
        $script:QaContent.PostId = $script:QaContent.PostDraftId
    }

    $event = Invoke-QaRequest -Method POST -Path '/rest/v1/events?select=id' -Token $presidentA.Token -Body @{
        club_id = $script:ClubA.Id
        title = "qa-event-$($script:Timestamp)"
        description = 'QA private event'
        start_at = (Get-Date).AddDays(2).ToUniversalTime().ToString('o')
        end_at = (Get-Date).AddDays(2).AddHours(2).ToUniversalTime().ToString('o')
        created_by = $presidentA.Id
        visibility = 'club_only'
    } -ExtraHeaders @{ Prefer='return=representation' }
    Add-SetupResult -Id 'SEED-EVENT-PRIVATE' -Description 'Evento club_only QA' -Response $event
    if ($event.Status -ge 200 -and $event.Status -lt 300 -and $event.Json) {
        $script:QaContent.EventId = [string](Get-FirstRow $event.Json).id
    }

    $sponsor = Invoke-Rpc -Name create_sponsor -Token $presidentA.Token -Params @{
        p_club_id = $script:ClubA.Id
        p_name = "qa-sponsor-$($script:Timestamp)"
        p_website = $null
        p_contact_email = "qa-$($script:Timestamp)-sponsor@example.com"
        p_contact_phone = $null
        p_contract_start_date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')
        p_contract_end_date = (Get-Date).AddDays(30).ToString('yyyy-MM-dd')
        p_annual_amount = 1
        p_benefits = 'QA'
        p_is_public = $false
    }
    $sponsorRow = Get-FirstRow $sponsor.Json
    $sponsorCreated = $sponsor.Status -ge 200 -and $sponsor.Status -lt 300 -and $sponsorRow.success -eq $true
    Add-Result -Id 'SEED-SPONSOR-PRIVATE' -Description 'Presidente crea patrocinador no público por RPC' -Expected 'HTTP 2xx y success=true' -Actual "HTTP $($sponsor.Status): $(Get-Message $sponsor)" -Passed $sponsorCreated
    if ($sponsorCreated) { $script:QaContent.SponsorId = [string]$sponsorRow.sponsor_id }
    $secretarySponsor = Invoke-Rpc -Name create_sponsor -Token $script:Actors['club_secretary'].Token -Params @{
        p_club_id = $script:ClubA.Id; p_name = "qa-secretary-sponsor-$($script:Timestamp)"
        p_website = $null; p_contact_email = $null; p_contact_phone = $null
        p_contract_start_date = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')
        p_contract_end_date = (Get-Date).AddDays(30).ToString('yyyy-MM-dd')
        p_annual_amount = 1; p_benefits = 'QA'; p_is_public = $false
    }
    $secretarySponsorRow = Get-FirstRow $secretarySponsor.Json
    Add-Result -Id 'SPONSOR-SECRETARY-DENIED' -Description 'Secretaría intenta crear patrocinador' -Expected 'success=false por permiso' -Actual "HTTP $($secretarySponsor.Status): $(Get-Message $secretarySponsor)" -Passed ($secretarySponsor.Status -ge 200 -and $secretarySponsor.Status -lt 300 -and $secretarySponsorRow.success -eq $false)

    foreach ($target in @('all_members','managers')) {
        $notification = Invoke-QaRequest -Method POST -Path '/rest/v1/notifications?select=id' -Token $presidentA.Token -Body @{
            club_id = $script:ClubA.Id
            title = "qa-$target-$($script:Timestamp)"
            body = 'QA notification'
            type = 'other'
            target = $target
        } -ExtraHeaders @{ Prefer='return=representation' }
        Add-SetupResult -Id "SEED-NOTIFICATION-$target" -Description "Notificación $target QA" -Response $notification
        if ($notification.Status -ge 200 -and $notification.Status -lt 300 -and $notification.Json) {
            $row = if ($notification.Json -is [array]) { $notification.Json[0] } else { $notification.Json }
            $script:QaContent["Notification-$target"] = [string]$row.id
        }
    }

    $raffleSlug = "qa-raffle-$($script:Timestamp)"
    $raffle = Invoke-QaRequest -Method POST -Path '/rest/v1/raffles?select=id,slug' -Token $presidentA.Token -Body @{
        club_id = $script:ClubA.Id
        slug = $raffleSlug
        title = "qa-raffle-$($script:Timestamp)"
        description = 'QA only'
        ticket_price = 1
        total_numbers = 20
        start_at = (Get-Date).AddMinutes(-1).ToUniversalTime().ToString('o')
        end_at = (Get-Date).AddDays(2).ToUniversalTime().ToString('o')
        draw_at = (Get-Date).AddDays(3).ToUniversalTime().ToString('o')
        status = 'active'
        raffle_type = 'sorteoPuro'
        created_by = $presidentA.Id
    } -ExtraHeaders @{ Prefer='return=representation' }
    Add-SetupResult -Id 'SEED-RAFFLE-ACTIVE' -Description 'Rifa activa y con fin futuro QA' -Response $raffle
    if ($raffle.Status -ge 200 -and $raffle.Status -lt 300 -and $raffle.Json) {
        $raffleRow = Get-FirstRow $raffle.Json
        $script:PublicRaffle = @{ Id=[string]$raffleRow.id; Slug=$raffleSlug }
        $script:QaContent.RaffleId = [string]$raffleRow.id
    }
    $endedRaffle = Invoke-QaRequest -Method POST -Path '/rest/v1/raffles?select=id' -Token $presidentA.Token -Body @{
        club_id = $script:ClubA.Id
        slug = "qa-ended-raffle-$($script:Timestamp)"
        title = "QA ended raffle $($script:Timestamp)"
        description = 'QA only'
        ticket_price = 1
        total_numbers = 20
        start_at = (Get-Date).AddDays(-5).ToUniversalTime().ToString('o')
        end_at = (Get-Date).AddDays(-1).ToUniversalTime().ToString('o')
        draw_at = (Get-Date).AddDays(1).ToUniversalTime().ToString('o')
        status = 'active'
        raffle_type = 'sorteoPuro'
        created_by = $presidentA.Id
    } -ExtraHeaders @{ Prefer='return=representation' }
    Add-SetupResult -Id 'SEED-RAFFLE-ENDED' -Description 'Rifa QA activa con fecha final pasada y sin tickets pagados' -Response $endedRaffle
    if ($endedRaffle.Status -ge 200 -and $endedRaffle.Status -lt 300) {
        $script:QaContent.EndedRaffleId = [string](Get-FirstRow $endedRaffle.Json).id
    }
    if ($script:PublicRaffle) {
        $preseedTicket = Invoke-Rpc -Name reserve_public_raffle_numbers -Params @{
            target_club_slug=$script:ClubA.Slug; target_raffle_slug=$script:PublicRaffle.Slug
            selected_numbers=@(1); target_buyer_name="QA buyer preseed $($script:Timestamp)"
            target_buyer_email="qa-$($script:Timestamp)-buyer-preseed@example.com"; target_buyer_phone=$null
        }
        Add-Result -Id 'SEED-PUBLIC-TICKET' -Description 'Anon reserva un ticket QA para probar lectura restringida' -Expected 'HTTP 2xx' -Actual "HTTP $($preseedTicket.Status)" -Passed ($preseedTicket.Status -ge 200 -and $preseedTicket.Status -lt 300)
    }

    $script:QaContentB = New-ClubFixtures -President $presidentB -Club $script:ClubB -Label 'b' -MemberNumber ([int]("2" + (Get-Date -Format 'MMddHHmm')))
    $script:QaContent.SeasonId = [string]$seasonRow.id
    $accountA = Get-RestRows -Table financial_accounts -Query "select=id&club_id=eq.$($script:ClubA.Id)&limit=1" -Token $presidentA.Token
    $accountB = Get-RestRows -Table financial_accounts -Query "select=id&club_id=eq.$($script:ClubB.Id)&limit=1" -Token $presidentB.Token
    $membershipA = Invoke-QaRequest -Method POST -Path '/rest/v1/memberships?select=id' -Token $presidentA.Token -Body @{
        club_id=$script:ClubA.Id; profile_id=$presidentA.Id
        member_number=[int]("1" + (Get-Date -Format 'MMddHHmm'))
        membership_type='standard'; status='active'
    } -ExtraHeaders @{ Prefer='return=representation' }
    if ($membershipA.Status -ge 200 -and $membershipA.Status -lt 300) {
        $script:QaContent.MembershipId = [string](Get-FirstRow $membershipA.Json).id
    }
    foreach ($profile in @(
        @{ Actor=$presidentA; Id=$presidentA.Id; Label='a'; Club=$script:ClubA; Account=$accountA }
        @{ Actor=$presidentB; Id=$presidentB.Id; Label='b'; Club=$script:ClubB; Account=$accountB }
    )) {
        $account = Get-FirstRow $profile.Account.Json
        if ($account) {
            $transaction = Invoke-QaRequest -Method POST -Path '/rest/v1/financial_transactions?select=id' -Token $profile.Actor.Token -Body @{
                club_id = $profile.Club.Id; account_id = $account.id; type = 'income'; category = 'other'
                amount = 1; description = "qa-transaction-$($profile.Label)-$($script:Timestamp)"
                created_by = $profile.Id
            } -ExtraHeaders @{ Prefer='return=representation' }
            if ($transaction.Status -ge 200 -and $transaction.Status -lt 300) {
                $fixtureSet = if ($profile.Label -eq 'a') { $script:QaContent } else { $script:QaContentB }
                $fixtureSet.TransactionId = [string](Get-FirstRow $transaction.Json).id
            }
        }
    }

    foreach ($label in @('president','treasurer','secretary','coach')) {
        Invoke-ReadMatrix -Actor $roles[$label] -ClubId $script:ClubA.Id -Label $label
    }
    $treasurerProfileStar = Get-RestRows -Table profiles -Query "select=*&id=eq.$($treasurer.Id)" -Token $treasurer.Token
    Add-Result -Id 'PROFILE-TREASURER-STAR' -Description 'Tesorería intenta select=* en profiles' -Expected 'HTTP 401/403 por columnas restringidas' -Actual "HTTP $($treasurerProfileStar.Status): $(Get-Message $treasurerProfileStar)" -Passed ($treasurerProfileStar.Status -in @(401,403))
    $foreignProfileByTreasurer = Get-RestRows -Table profiles -Query "select=id,email&id=eq.$($presidentB.Id)" -Token $treasurer.Token
    $foreignProfileCount = Get-RowCount $foreignProfileByTreasurer
    Add-Result -Id 'PROFILE-TREASURER-OTHER-CLUB' -Description 'Tesorería intenta leer perfil de presidente de otro club' -Expected 'cero filas o denegación' -Actual "HTTP $($foreignProfileByTreasurer.Status), filas=$foreignProfileCount" -Passed (($foreignProfileByTreasurer.Status -in @(401,403)) -or ($foreignProfileByTreasurer.Status -ge 200 -and $foreignProfileCount -eq 0))
    if ($script:QaContent.PlayerId) {
        $coachWrite = Invoke-QaRequest -Method PATCH -Path "/rest/v1/players?id=eq.$($script:QaContent.PlayerId)&select=id" -Token $script:Actors['coach'].Token -Body @{
            updated_at=(Get-Date).ToUniversalTime().ToString('o')
        } -ExtraHeaders @{ Prefer='return=representation' }
        $coachWriteCount = Get-RowCount $coachWrite
        Add-Result -Id 'COACH-PLAYER-WRITE' -Description 'Entrenador intenta modificar un jugador QA' -Expected 'denegación o cero filas (solo lectura)' -Actual "HTTP $($coachWrite.Status), filas=$($coachWriteCount): $(Get-Message $coachWrite)" -Passed (($coachWrite.Status -in @(401,403)) -or ($coachWrite.Status -ge 200 -and $coachWriteCount -eq 0))
    }

    # Read-only catalog queries establish the real policy state used by this test run.
    $catalogChecks = @(
        @{ Id='CAT-NO-RLS'; Sql="select count(*) as count from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p') and not c.relrowsecurity;" }
        @{ Id='CAT-PROFILE-ORPHANS'; Sql="select count(*) as count from auth.users u left join public.profiles p on p.id=u.id where p.id is null;" }
    )
    foreach ($check in $catalogChecks) {
        try {
            $rows = Get-DbQueryRows $check.Sql
            $value = [int]$rows[0].count
            $expected = if ($check.Id -eq 'CAT-PROFILE-ORPHANS') { '0 usuarios auth sin profile' } else { '0' }
            Add-Result -Id $check.Id -Description 'Consulta de solo lectura a catálogo remoto' -Expected $expected -Actual "db query --linked count=$value" -Passed ($value -eq 0)
        } catch {
            Add-Result -Id $check.Id -Description 'Consulta de solo lectura a catálogo remoto' -Expected 'resultado verificable' -Actual $_.Exception.Message -Passed $false -State 'BLOQUEADO'
        }
    }
    $openPolicies = Get-DbQueryRows "select tablename, policyname, cmd, roles::text as roles, coalesce(qual,'') as using_expr, coalesce(with_check,'') as check_expr from pg_policies where schemaname='public' and (lower(coalesce(qual,''))='true' or lower(coalesce(with_check,''))='true') order by tablename,policyname"
    $openSummary = @($openPolicies | ForEach-Object { "$($_.tablename).$($_.policyname)[$($_.cmd);$($_.roles)]" }) -join '; '
    Add-Result -Id 'CAT-OPEN-POLICIES' -Description 'Enumera políticas que permiten true sin restricciones' -Expected 'lista revisada; no omitir ninguna' -Actual "count=$(@($openPolicies).Count): $openSummary" -Passed $true
    $weakDefiners = Get-DbQueryRows "select p.proname, pg_get_function_identity_arguments(p.oid) as args from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.prosecdef and has_function_privilege('authenticated',p.oid,'EXECUTE') and lower(pg_get_functiondef(p.oid)) not like '%auth.uid%' and lower(pg_get_functiondef(p.oid)) not like '%auth.role%' and lower(pg_get_functiondef(p.oid)) not like '%has_club_permission%' and lower(pg_get_functiondef(p.oid)) not like '%is_club_manager%' and lower(pg_get_functiondef(p.oid)) not like '%is_club_member%' order by p.proname"
    $weakSummary = @($weakDefiners | ForEach-Object { "$($_.proname)($($_.args))" }) -join '; '
    Add-Result -Id 'CAT-DEFINER-REVIEW' -Description 'Enumera SECURITY DEFINER ejecutables por authenticated sin guardas de permiso detectables' -Expected 'lista revisada función por función' -Actual "count=$(@($weakDefiners).Count): $weakSummary" -Passed $true

    # Matrix tests use the current QA rows and distinguish allowed empty responses from RLS-filtered rows.
    $anon = $script:AnonKey
    foreach ($table in @('financial_transactions','financial_accounts','players','teams','team_players','team_staff','seasons','posts','events','raffle_tickets','raffle_draws','raffle_monthly_results','raffle_monthly_subscriptions','profiles','club_memberships','memberships','sponsors','notifications','notification_deliveries','user_devices','audit_logs','club_role_permissions')) {
        $query = if ($table -eq 'club_role_permissions') { 'select=role&limit=1' } else { 'select=id&limit=1' }
        $response = Get-RestRows -Table $table -Query $query -Token $anon
        $empty = Get-RowCount $response
        $passed = ($response.Status -in @(401,403)) -or ($response.Status -ge 200 -and $response.Status -lt 300 -and $empty -eq 0)
        Add-Result -Id "ANON-TABLE-$table" -Description "Anon GET $table" -Expected '401/403 o HTTP 2xx con cero filas' -Actual "HTTP $($response.Status), filas=$empty, $(Get-Message $response)" -Passed $passed
    }

    foreach ($spec in @(
        @{ Query='select=id,public_name,slug&limit=10'; Allowed=$true; Name='clubs-public-columns' },
        @{ Query='select=legal_name&limit=1'; Allowed=$false; Name='clubs-legal-name' },
        @{ Query='select=*&limit=1'; Allowed=$false; Name='clubs-star' },
        @{ Query='select=id,club_id&limit=1'; Allowed=$false; Name='raffles-club-id' },
        @{ Query='select=id,slug,title,description,image_url,ticket_price,total_numbers,end_at,status,raffle_type,winning_number,monthly_day,subscription_enabled&limit=5'; Allowed=$true; Name='raffles-public-columns' }
    )) {
        $tableName = if ($spec.Name.StartsWith('clubs')) { 'clubs' } else { 'raffles' }
        $response = Get-RestRows -Table $tableName -Query $spec.Query -Token $anon
        $ok = if ($spec.Allowed) { $response.Status -ge 200 -and $response.Status -lt 300 } else { $response.Status -in @(401,403) }
        Add-Result -Id "ANON-$($spec.Name)" -Description 'Column grant anónimo' -Expected $(if ($spec.Allowed) { 'HTTP 2xx' } else { 'HTTP 401/403 por privilegio de columna' }) -Actual "HTTP $($response.Status): $(Get-Message $response)" -Passed $ok
    }

    if ($script:PublicRaffle) {
        $slug = $script:ClubA.Slug
        $rSlug = $script:PublicRaffle.Slug
        foreach ($rpc in @('get_public_club','get_public_events','get_public_posts','get_public_sponsors','get_public_raffle_numbers')) {
            $params = @{ target_club_slug = $slug }
            if ($rpc -eq 'get_public_raffle_numbers') { $params.target_raffle_slug = $rSlug }
            $response = Invoke-Rpc -Name $rpc -Params $params
            $bodyText = [string]$response.Content
            $hasPrivate = $bodyText -match '(?i)(email|phone|contact_email|buyer_profile_id|buyer_email|buyer_phone)'
            Add-Result -Id "PUBLIC-RPC-$rpc" -Description "RPC pública $rpc y revisión de PII" -Expected 'HTTP 2xx; sin email/teléfono/contact_email/buyer_*' -Actual "HTTP $($response.Status): $(Get-Message $response)" -Passed ($response.Status -ge 200 -and $response.Status -lt 300 -and -not $hasPrivate)
        }
        $hasActive = Invoke-Rpc -Name has_public_active_raffle -Params @{ target_club_id=$script:ClubA.Id }
        $hasActiveText = [string]$hasActive.Content
        Add-Result -Id 'PUBLIC-RPC-has_public_active_raffle' -Description 'RPC pública has_public_active_raffle y PII' -Expected 'HTTP 2xx true sin datos personales' -Actual "HTTP $($hasActive.Status): $(Get-Message $hasActive)" -Passed ($hasActive.Status -ge 200 -and $hasActive.Status -lt 300 -and $hasActive.Json -eq $true -and $hasActiveText -notmatch '(?i)(email|phone|contact_email|buyer_)')
        $unknown = Invoke-Rpc -Name 'get_public_club' -Params @{ target_club_slug = "qa-missing-$($script:Timestamp)" }
        $unknownCount = Get-RowCount $unknown
        Add-Result -Id 'PUBLIC-UNKNOWN-SLUG' -Description 'RPC pública slug inexistente' -Expected 'HTTP 2xx y cero filas' -Actual "HTTP $($unknown.Status), filas=$unknownCount" -Passed ($unknown.Status -ge 200 -and $unknown.Status -lt 300 -and $unknownCount -eq 0)

        $validReserve = Invoke-Rpc -Name 'reserve_public_raffle_numbers' -Params @{
            target_club_slug = $slug; target_raffle_slug = $rSlug; selected_numbers = @(2)
            target_buyer_name = "QA buyer $($script:Timestamp)"
            target_buyer_email = "qa-$($script:Timestamp)-buyer@example.com"
            target_buyer_phone = $null
        }
        $validReserveNumber = [int]$validReserve.Json
        Add-Result -Id 'RAFFLE-RESERVE-VALID' -Description 'Anon reserva un número usando la firma remota completa' -Expected 'HTTP 2xx y número 2' -Actual "HTTP $($validReserve.Status): $(Get-Message $validReserve)" -Passed ($validReserve.Status -ge 200 -and $validReserve.Status -lt 300 -and $validReserveNumber -eq 2)
        $badCases = @(
            @{ Id='DUPLICATE'; Numbers=@(2); Email="qa-$($script:Timestamp)-dup@example.com"; Expected='disponible' }
            @{ Id='OUT-OF-RANGE'; Numbers=@(21); Email="qa-$($script:Timestamp)-range@example.com"; Expected='no valido' }
            @{ Id='OVER-TEN'; Numbers=@(2,3,4,5,6,7,8,9,10,11,12); Email="qa-$($script:Timestamp)-many@example.com"; Expected='entre 1 y 10' }
            @{ Id='INVALID-EMAIL'; Numbers=@(13); Email='no-es-email'; Expected='datos del comprador no son validos' }
            @{ Id='MISSING-SLUG'; Numbers=@(14); Email="qa-$($script:Timestamp)-missing@example.com"; Expected='no esta disponible' }
        )
        foreach ($case in $badCases) {
            $clubSlugForCase = if ($case.Id -eq 'MISSING-SLUG') { "qa-missing-$($script:Timestamp)" } else { $slug }
            $response = Invoke-Rpc -Name 'reserve_public_raffle_numbers' -Params @{
                target_club_slug = $clubSlugForCase; target_raffle_slug = $rSlug; selected_numbers = $case.Numbers
                target_buyer_name = 'QA Test'; target_buyer_email = $case.Email; target_buyer_phone = $null
            }
            $message = Get-Message $response
            $passed = $response.Status -eq 400 -and (Normalize-Text $message).Contains((Normalize-Text $case.Expected))
            Add-Result -Id "RAFFLE-RESERVE-$($case.Id)" -Description "Reserva inválida: $($case.Id)" -Expected "HTTP 400 mensaje contiene '$($case.Expected)'" -Actual "HTTP $($response.Status): $message" -Passed $passed
        }

        foreach ($role in @('club_secretary','coach')) {
            $actor = $script:Actors[$role]
            foreach ($rpc in @('set_raffle_manual_winner','draw_raffle_random_secure')) {
                $params = if ($rpc -eq 'set_raffle_manual_winner') { @{ target_raffle_id=$script:PublicRaffle.Id; target_winning_number=1 } } else { @{ target_raffle_id=$script:PublicRaffle.Id } }
                $response = Invoke-Rpc -Name $rpc -Params $params -Token $actor.Token
                $message = Get-Message $response
                $passed = $response.Status -eq 400 -and $message -match '(?i)permiso'
                Add-Result -Id "RAFFLE-$role-$rpc" -Description "$role intenta $rpc" -Expected 'HTTP 400 por permiso' -Actual "HTTP $($response.Status): $message" -Passed $passed
            }
        }
        $earlyDraw = Invoke-Rpc -Name draw_raffle_random_secure -Params @{ target_raffle_id=$script:PublicRaffle.Id } -Token $presidentA.Token
        Add-Result -Id 'RAFFLE-DRAW-EARLY' -Description 'Presidente sortea antes de end_at' -Expected 'HTTP 400 con todavia no ha terminado' -Actual "HTTP $($earlyDraw.Status): $(Get-Message $earlyDraw)" -Passed ($earlyDraw.Status -eq 400 -and (Normalize-Text (Get-Message $earlyDraw)) -match 'todavia no ha terminado')
        $endedId = [string]$script:QaContent.EndedRaffleId
        $noPaidDraw = Invoke-Rpc -Name draw_raffle_random_secure -Params @{ target_raffle_id=$endedId } -Token $presidentA.Token
        Add-Result -Id 'RAFFLE-DRAW-NO-PAID' -Description 'Presidente sortea rifa QA finalizada sin tickets pagados' -Expected 'HTTP 400 con no hay participaciones confirmadas' -Actual "HTTP $($noPaidDraw.Status): $(Get-Message $noPaidDraw)" -Passed ($noPaidDraw.Status -eq 400 -and (Normalize-Text (Get-Message $noPaidDraw)) -match 'no hay participaciones confirmadas')
        Add-Result -Id 'RAFFLE-DRAW-WITH-PAID-TICKET' -Description 'Sorteo de rifa finalizada con ticket pagado QA' -Expected 'sorteo exitoso y número ganador de ticket pagado' -Actual 'NO EJECUTADO: requiere ejecutar docs/sql/qa_seed.sql manualmente en una transacción' -Passed $false -State 'BLOQUEADO'
        $legacy = Invoke-Rpc -Name draw_raffle_random -Params @{ target_raffle_id=$script:PublicRaffle.Id } -Token $presidentA.Token
        Add-Result -Id 'RAFFLE-LEGACY-DRAW' -Description 'Presidente intenta RPC de sorteo legado' -Expected 'denegación, no éxito' -Actual "HTTP $($legacy.Status): $(Get-Message $legacy)" -Passed ($legacy.Status -in @(401,403,404))
        $record = Invoke-Rpc -Name record_raffle_payment -Params @{ target_ticket_id='00000000-0000-0000-0000-000000000000'; target_profile_id=$presidentA.Id; target_payment_reference='qa-ref' } -Token $presidentA.Token
        Add-Result -Id 'RAFFLE-RECORD-PAYMENT' -Description 'Presidente intenta RPC solo backend de pago' -Expected 'denegación, no éxito' -Actual "HTTP $($record.Status): $(Get-Message $record)" -Passed ($record.Status -in @(401,403,404))
    } else {
        Add-Result -Id 'RAFFLE-SCENARIO' -Description 'Pruebas de rifa requieren rifa QA creada' -Expected 'ejecución completa' -Actual 'No se creó la rifa QA' -Passed $false -State 'BLOQUEADO'
    }

    # Password flag: direct update is denied, password changes via Auth, then self-only RPC clears the flag.
    $treasurer = $script:Actors['club_treasurer']
    $flag = Get-RestRows -Table profiles -Query "select=id,must_change_password&id=eq.$($treasurer.Id)" -Token $presidentA.Token
    $directFlag = Invoke-QaRequest -Method PATCH -Path "/rest/v1/profiles?id=eq.$($treasurer.Id)" -Token $treasurer.Token -Body @{ must_change_password=$false }
    Add-Result -Id 'PASSWORD-FLAG-DIRECT' -Description 'Usuario intenta borrar must_change_password directamente' -Expected 'HTTP 401/403' -Actual "HTTP $($directFlag.Status): $(Get-Message $directFlag)" -Passed ($directFlag.Status -in @(401,403))
    $newPassword = New-RandomPassword
    $changePassword = Invoke-QaRequest -Method PUT -Path '/auth/v1/user' -Token $treasurer.Token -Body @{ password=$newPassword }
    Add-Result -Id 'PASSWORD-CHANGE' -Description 'Usuario cambia contraseña por Auth API' -Expected 'HTTP 2xx' -Actual "HTTP $($changePassword.Status)" -Passed ($changePassword.Status -ge 200 -and $changePassword.Status -lt 300)
    if ($changePassword.Status -ge 200 -and $changePassword.Status -lt 300) {
        $treasurer.Password = $newPassword
        $login = Invoke-QaRequest -Method POST -Path '/auth/v1/token?grant_type=password' -Body @{ email=$treasurer.Email; password=$newPassword }
        if ($login.Status -ge 200 -and $login.Status -lt 300 -and $login.Json.access_token) { $treasurer.Token = [string]$login.Json.access_token }
        $clear = Invoke-Rpc -Name clear_must_change_password -Params @{} -Token $treasurer.Token
        Add-Result -Id 'PASSWORD-CLEAR-RPC' -Description 'Usuario llama clear_must_change_password con JWT propio' -Expected 'HTTP 2xx true' -Actual "HTTP $($clear.Status): $(Get-Message $clear)" -Passed ($clear.Status -ge 200 -and $clear.Status -lt 300)
    }

    $changeToPresident = Invoke-Rpc -Name change_member_role -Params @{
        p_club_id=$script:ClubA.Id; p_profile_id=$treasurer.Id; p_role='club_president'
    } -Token $presidentA.Token
    Add-Result -Id 'ACCESS-NAME-PRESIDENT' -Description 'Presidente intenta nombrar presidente por change_member_role' -Expected 'HTTP 2xx con success=false o denegación' -Actual "HTTP $($changeToPresident.Status): $(Get-Message $changeToPresident)" -Passed (($changeToPresident.Status -ge 200 -and $changeToPresident.Status -lt 300 -and -not (Get-FirstRow $changeToPresident.Json).success) -or $changeToPresident.Status -in @(401,403))
    $revokeSelf = Invoke-Rpc -Name revoke_member_access -Params @{ p_club_id=$script:ClubA.Id; p_profile_id=$presidentA.Id } -Token $presidentA.Token
    Add-Result -Id 'ACCESS-REVOKE-SOLE-PRESIDENT' -Description 'Presidente intenta revocarse como único presidente' -Expected 'HTTP 2xx con success=false o denegación' -Actual "HTTP $($revokeSelf.Status): $(Get-Message $revokeSelf)" -Passed (($revokeSelf.Status -ge 200 -and $revokeSelf.Status -lt 300 -and -not (Get-FirstRow $revokeSelf.Json).success) -or $revokeSelf.Status -in @(401,403))
    $degradeSelf = Invoke-Rpc -Name change_member_role -Params @{
        p_club_id=$script:ClubA.Id; p_profile_id=$presidentA.Id; p_role='club_secretary'
    } -Token $presidentA.Token
    Add-Result -Id 'ACCESS-DEGRADE-SOLE-PRESIDENT' -Description 'Presidente intenta degradarse como único presidente' -Expected 'HTTP 2xx con success=false o denegación' -Actual "HTTP $($degradeSelf.Status): $(Get-Message $degradeSelf)" -Passed (($degradeSelf.Status -ge 200 -and $degradeSelf.Status -lt 300 -and -not (Get-FirstRow $degradeSelf.Json).success) -or $degradeSelf.Status -in @(401,403))

    # Notification visibility and delivery ownership.
    foreach ($target in @('all_members','managers')) {
        $notificationId = $script:QaContent["Notification-$target"]
        if (-not $notificationId) {
            Add-Result -Id "NOTIFY-$target-SEED" -Description 'Notificación QA creada antes de consultar' -Expected 'seed disponible' -Actual 'no creada' -Passed $false -State 'BLOQUEADO'
            continue
        }
        $rows = Get-RestRows -Table notification_deliveries -Query "select=id,notification_id,profile_id,read_at&notification_id=eq.$notificationId&profile_id=eq.$($treasurer.Id)" -Token $treasurer.Token
        $count = Get-RowCount $rows
        $expectedCount = if ($target -eq 'all_members') { 1 } else { 0 }
        Add-Result -Id "NOTIFY-TREASURER-$target" -Description "Tesorería recibe $target" -Expected "filas=$expectedCount" -Actual "HTTP $($rows.Status), filas=$count" -Passed ($rows.Status -ge 200 -and $rows.Status -lt 300 -and $count -eq $expectedCount)
    }
    $ownDelivery = Get-RestRows -Table notification_deliveries -Query "select=id,notification_id,profile_id,read_at&notification_id=eq.$($script:QaContent['Notification-all_members'])&profile_id=eq.$($treasurer.Id)" -Token $treasurer.Token
    if ((Get-RowCount $ownDelivery) -gt 0) {
        $deliveryId = [string]$ownDelivery.Json[0].id
        $markOwn = Invoke-Rpc -Name mark_notification_delivery_read -Params @{ p_delivery_id=$deliveryId } -Token $treasurer.Token
        Add-Result -Id 'NOTIFY-MARK-OWN' -Description 'Usuario marca su entrega como leída' -Expected 'HTTP 2xx' -Actual "HTTP $($markOwn.Status)" -Passed ($markOwn.Status -ge 200 -and $markOwn.Status -lt 300)
    }
    $presidentDelivery = Get-RestRows -Table notification_deliveries -Query "select=id,notification_id,profile_id&notification_id=eq.$($script:QaContent['Notification-all_members'])&profile_id=eq.$($presidentA.Id)" -Token $presidentA.Token
    if ((Get-RowCount $presidentDelivery) -gt 0) {
        $otherDeliveryId = [string]$presidentDelivery.Json[0].id
        $markOther = Invoke-Rpc -Name mark_notification_delivery_read -Params @{ p_delivery_id=$otherDeliveryId } -Token $treasurer.Token
        $checkOther = Get-RestRows -Table notification_deliveries -Query "select=read_at&id=eq.$otherDeliveryId" -Token $presidentA.Token
        $stillUnread = $checkOther.Json -and $null -eq $checkOther.Json[0].read_at
        Add-Result -Id 'NOTIFY-MARK-OTHER' -Description 'Tesorería intenta marcar la entrega del presidente' -Expected 'sin cambio en read_at ajeno' -Actual "HTTP RPC $($markOther.Status); read_at_presidente_sigue_nulo=$stillUnread" -Passed $stillUnread
    } else {
        Add-Result -Id 'NOTIFY-MARK-OTHER' -Description 'Entrega QA del presidente requerida' -Expected 'seed disponible' -Actual 'no encontrada' -Passed $false -State 'BLOQUEADO'
    }

    # Cross-club reads and function-level authorization checks. Every checked row is created by this run.
    foreach ($pair in @(
        @{ Actor=$presidentA; Other=$script:ClubB; Target=$script:ClubB; Label='A-to-B' }
        @{ Actor=$presidentB; Other=$script:ClubA; Target=$script:ClubA; Label='B-to-A' }
    )) {
        foreach ($table in @('memberships','financial_accounts','financial_transactions','teams','players','team_players','team_staff','seasons','raffles','raffle_tickets','raffle_draws','posts','events','sponsors','notifications')) {
            $response = Get-RestRows -Table $table -Query "select=id,club_id&club_id=eq.$($pair.Target.Id)" -Token $pair.Actor.Token
            $count = Get-RowCount $response
            $passed = ($response.Status -in @(401,403)) -or ($response.Status -ge 200 -and $response.Status -lt 300 -and $count -eq 0)
            Add-Result -Id "ISOLATION-$($pair.Label)-READ-$table" -Description "$($pair.Label): lectura de $table del otro club" -Expected '401/403 o cero filas' -Actual "HTTP $($response.Status), filas=$count" -Passed $passed
        }
        $otherActorId = if ($pair.Label -eq 'A-to-B') { $presidentB.Id } else { $presidentA.Id }
        $deliveries = Get-RestRows -Table notification_deliveries -Query "select=id,notification_id,profile_id&profile_id=eq.$otherActorId" -Token $pair.Actor.Token
        $deliveryCount = Get-RowCount $deliveries
        Add-Result -Id "ISOLATION-$($pair.Label)-READ-notification_deliveries" -Description "$($pair.Label): consulta entregas del otro perfil" -Expected '401/403 o cero filas' -Actual "HTTP $($deliveries.Status), filas=$deliveryCount" -Passed (($deliveries.Status -in @(401,403)) -or ($deliveries.Status -ge 200 -and $deliveryCount -eq 0))
        $foreignProfile = if ($pair.Label -eq 'A-to-B') { $presidentB.Id } else { $presidentA.Id }
        $profileResponse = Get-RestRows -Table profiles -Query "select=id,email&id=eq.$foreignProfile" -Token $pair.Actor.Token
        $profileCount = Get-RowCount $profileResponse
        Add-Result -Id "ISOLATION-$($pair.Label)-PROFILE" -Description "$($pair.Label): lectura del perfil de otro club" -Expected '401/403 o cero filas' -Actual "HTTP $($profileResponse.Status), filas=$profileCount" -Passed (($profileResponse.Status -in @(401,403)) -or ($profileResponse.Status -ge 200 -and $profileResponse.Status -lt 300 -and $profileCount -eq 0))
        $crossRole = Invoke-Rpc -Name change_member_role -Params @{
            p_club_id=$pair.Target.Id; p_profile_id=$foreignProfile; p_role='member'
        } -Token $pair.Actor.Token
        $crossMessage = Get-Message $crossRole
        $crossDenied = $crossRole.Status -in @(401,403) -or ($crossRole.Status -ge 200 -and $crossRole.Status -lt 300 -and $crossMessage -match '(?i)no tienes permiso|usuario no tiene|no es miembro')
        Add-Result -Id "ISOLATION-$($pair.Label)-RPC" -Description "$($pair.Label): change_member_role sobre el otro club" -Expected 'denegación o success=false por autorización' -Actual "HTTP $($crossRole.Status): $crossMessage" -Passed $crossDenied

        $targetFixture = if ($pair.Label -eq 'A-to-B') { $script:QaContentB } else { $script:QaContent }
        $writeCases = @(
            @{ Table='memberships'; Id=$targetFixture.MembershipId; Field='notes'; Value="qa-blocked-$($script:Timestamp)" }
            @{ Table='teams'; Id=$targetFixture.TeamId; Field='name'; Value="qa-blocked-$($script:Timestamp)" }
            @{ Table='players'; Id=$targetFixture.PlayerId; Field='updated_at'; Value=(Get-Date).ToUniversalTime().ToString('o') }
            @{ Table='team_players'; Id=$targetFixture.TeamPlayerId; Field='jersey_number'; Value=99 }
            @{ Table='seasons'; Id=$targetFixture.SeasonId; Field='name'; Value="qa-blocked-$($script:Timestamp)" }
            @{ Table='posts'; Id=$targetFixture.PostId; Field='title'; Value="qa-blocked-$($script:Timestamp)" }
            @{ Table='events'; Id=$targetFixture.EventId; Field='title'; Value="qa-blocked-$($script:Timestamp)" }
            @{ Table='raffles'; Id=$targetFixture.RaffleId; Field='title'; Value="qa-blocked-$($script:Timestamp)" }
            @{ Table='financial_transactions'; Id=$targetFixture.TransactionId; Field='description'; Value="qa-blocked-$($script:Timestamp)" }
        )
        foreach ($write in $writeCases) {
            if ([string]::IsNullOrWhiteSpace([string]$write.Id)) {
                Add-Result -Id "ISOLATION-$($pair.Label)-WRITE-$($write.Table)" -Description 'Escritura cruzada de dato QA' -Expected 'fila QA objetivo disponible' -Actual 'NO EJECUTADO: no se creó fila fixture' -Passed $false -State 'BLOQUEADO'
                continue
            }
            $patchPath = "/rest/v1/$($write.Table)?id=eq.$($write.Id)&select=id"
            $patchBody = @{}
            $patchBody[$write.Field] = $write.Value
            $writeResponse = Invoke-QaRequest -Method PATCH -Path $patchPath -Token $pair.Actor.Token -Body $patchBody -ExtraHeaders @{ Prefer='return=representation' }
            $writeCount = Get-RowCount $writeResponse
            $writeDenied = ($writeResponse.Status -in @(401,403)) -or ($writeResponse.Status -ge 200 -and $writeCount -eq 0)
            Add-Result -Id "ISOLATION-$($pair.Label)-WRITE-$($write.Table)" -Description "$($pair.Label): modifica fila QA ajena en $($write.Table)" -Expected '401/403 o cero filas afectadas' -Actual "HTTP $($writeResponse.Status), filas=$writeCount" -Passed $writeDenied
        }
    }

    # Anonymous writes target only the QA club/raffle and cannot modify non-QA rows.
    $anonPatch = Invoke-QaRequest -Method PATCH -Path "/rest/v1/clubs?id=eq.$($script:ClubA.Id)" -Token $anon -Body @{ public_name="qa-denied-$($script:Timestamp)" } -ExtraHeaders @{ Prefer='return=representation' }
    Add-Result -Id 'ANON-WRITE-CLUB' -Description 'Anon intenta actualizar club QA' -Expected '401/403' -Actual "HTTP $($anonPatch.Status): $(Get-Message $anonPatch)" -Passed ($anonPatch.Status -in @(401,403))
    if ($script:PublicRaffle) {
        $anonRafflePatch = Invoke-QaRequest -Method PATCH -Path "/rest/v1/raffles?id=eq.$($script:PublicRaffle.Id)" -Token $anon -Body @{ title="qa-denied-$($script:Timestamp)" } -ExtraHeaders @{ Prefer='return=representation' }
        Add-Result -Id 'ANON-WRITE-RAFFLE' -Description 'Anon intenta actualizar rifa QA' -Expected '401/403' -Actual "HTTP $($anonRafflePatch.Status)" -Passed ($anonRafflePatch.Status -in @(401,403))
        $anonRaffleDelete = Invoke-QaRequest -Method DELETE -Path "/rest/v1/raffles?id=eq.$($script:PublicRaffle.Id)" -Token $anon
        Add-Result -Id 'ANON-DELETE-RAFFLE' -Description 'Anon intenta borrar rifa QA' -Expected '401/403' -Actual "HTTP $($anonRaffleDelete.Status)" -Passed ($anonRaffleDelete.Status -in @(401,403))
        $anonTicket = Invoke-QaRequest -Method POST -Path '/rest/v1/raffle_tickets' -Token $anon -Body @{
            club_id=$script:ClubA.Id; raffle_id=$script:PublicRaffle.Id; number=19
            buyer_name='QA Anon'; buyer_email="qa-$($script:Timestamp)-anon@example.com"
        }
        Add-Result -Id 'ANON-WRITE-RAFFLE-TICKETS' -Description 'Anon intenta insertar ticket directo (sin RPC)' -Expected '401/403' -Actual "HTTP $($anonTicket.Status): $(Get-Message $anonTicket)" -Passed ($anonTicket.Status -in @(401,403))
        $ticketRows = Get-RestRows -Table raffle_tickets -Query "select=id&raffle_id=eq.$($script:PublicRaffle.Id)&limit=1" -Token $presidentA.Token
        $ticketRow = Get-FirstRow $ticketRows.Json
        if ($ticketRow) {
            $anonTicketPatch = Invoke-QaRequest -Method PATCH -Path "/rest/v1/raffle_tickets?id=eq.$($ticketRow.id)" -Token $anon -Body @{ buyer_name='QA denied' }
            $anonTicketDelete = Invoke-QaRequest -Method DELETE -Path "/rest/v1/raffle_tickets?id=eq.$($ticketRow.id)" -Token $anon
            Add-Result -Id 'ANON-UPDATE-RAFFLE-TICKETS' -Description 'Anon intenta actualizar ticket QA' -Expected '401/403' -Actual "HTTP $($anonTicketPatch.Status)" -Passed ($anonTicketPatch.Status -in @(401,403))
            Add-Result -Id 'ANON-DELETE-RAFFLE-TICKETS' -Description 'Anon intenta borrar ticket QA' -Expected '401/403' -Actual "HTTP $($anonTicketDelete.Status)" -Passed ($anonTicketDelete.Status -in @(401,403))
        } else {
            Add-Result -Id 'ANON-UPDATE-RAFFLE-TICKETS' -Description 'Ticket QA necesario para probar escritura' -Expected 'fixture disponible' -Actual 'no encontrado' -Passed $false -State 'BLOQUEADO'
        }
    }
    $anonClubInsert = Invoke-QaRequest -Method POST -Path '/rest/v1/clubs' -Token $anon -Body @{
        legal_name="qa-anon-$($script:Timestamp)"; public_name="qa-anon-$($script:Timestamp)"; slug="qa-anon-$($script:Timestamp)"
    }
    Add-Result -Id 'ANON-INSERT-CLUB' -Description 'Anon intenta insertar club directo' -Expected '401/403' -Actual "HTTP $($anonClubInsert.Status): $(Get-Message $anonClubInsert)" -Passed ($anonClubInsert.Status -in @(401,403))

    # Public visibility checks target this run's club slug, not arbitrary production rows.
    if ($script:PublicRaffle) {
        foreach ($rpc in @('get_public_posts','get_public_events','get_public_sponsors')) {
            $response = Invoke-Rpc -Name $rpc -Params @{ target_club_slug=$script:ClubA.Slug }
            $bodyText = [string]$response.Content
            $marker = switch ($rpc) {
                'get_public_posts' { "qa-draft-$($script:Timestamp)" }
                'get_public_events' { "qa-event-$($script:Timestamp)" }
                'get_public_sponsors' { "qa-sponsor-$($script:Timestamp)" }
            }
            $notVisible = -not $bodyText.Contains($marker)
            Add-Result -Id "PUBLIC-HIDDEN-$rpc" -Description 'Contenido no público no aparece en RPC anon' -Expected 'HTTP 2xx y marker QA ausente' -Actual "HTTP $($response.Status); marker_ausente=$notVisible" -Passed ($response.Status -ge 200 -and $response.Status -lt 300 -and $notVisible)
        }
    }
} catch {
    Add-Result -Id 'RUN-ABORT' -Description 'Excepción durante la inicialización/ejecución del escenario' -Expected 'continuar con pruebas independientes' -Actual $_.Exception.Message -Passed $false -State 'BLOQUEADO'
}

Write-Host ''
Write-Host '=== QA users created (delete manually in Authentication > Users) ==='
foreach ($email in $script:QaUsers) { Write-Host $email }
Write-Host '=== Summary ==='
$summary = $script:Results | Group-Object State | ForEach-Object { "$($_.Name)=$($_.Count)" }
Write-Host ($summary -join ' ')
Write-Host "Total=$($script:Results.Count)"

$reportPath = Join-Path (Get-Location) 'docs\QA_REPORT_2026-10-06.md'
$reportLines = New-Object System.Collections.Generic.List[string]
$reportLines.Add('# Informe QA de seguridad E2E — 2026-10-06')
$reportLines.Add('')
$reportLines.Add("Ejecucion: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz') (PowerShell $($PSVersionTable.PSVersion)).")
$reportLines.Add('Entorno: Supabase remoto enlazado; solo solicitudes con publishable/anon y JWT de usuarios QA; catalogo por consultas `db query --linked` de solo lectura.')
$reportLines.Add('No se ejecutaron db push/reset/repair ni SQL de cambios de esquema/permisos. No se usaron ni imprimieron claves de service role.')
$reportLines.Add('')
$reportLines.Add('## Contadores')
foreach ($state in @('PASS','FAIL','BLOQUEADO','NO EJECUTADO')) {
    $count = @($script:Results | Where-Object State -eq $state).Count
    $reportLines.Add("- ${state}: $count")
}
$reportLines.Add("- Total: $($script:Results.Count)")
$reportLines.Add('')
$reportLines.Add('## Evidencia de pruebas')
$reportLines.Add('')
$reportLines.Add('| ID | Descripcion | Esperado | Obtenido (HTTP/comando) | Estado |')
$reportLines.Add('|----|-------------|----------|-------------------------|--------|')
foreach ($item in $script:Results) {
    $description = ([string]$item.Description).Replace('|','\|').Replace("`r",' ').Replace("`n",' ')
    $expected = ([string]$item.Expected).Replace('|','\|').Replace("`r",' ').Replace("`n",' ')
    $actual = ([string]$item.Actual).Replace('|','\|').Replace("`r",' ').Replace("`n",' ')
    $reportLines.Add("| $($item.Id) | $description | $expected | $actual | $($item.State) |")
}
$reportLines.Add('')
$reportLines.Add('## Hallazgos por severidad')
$reportLines.Add('')
$failedIds = @($script:Results | Where-Object State -eq 'FAIL' | ForEach-Object Id)
if ($failedIds -contains 'COACH-PLAYER-WRITE') {
    $item = $script:Results | Where-Object Id -eq 'COACH-PLAYER-WRITE' | Select-Object -First 1
    $reportLines.Add("- HIGH — El entrenador pudo modificar un jugador QA: $($item.Actual). Evidencia: `COACH-PLAYER-WRITE`; el borrador `docs/sql/050_draft.sql` retira `players_manage` a `coach`.")
}
if ($failedIds -contains 'PERMISSION-PRESIDENT-sponsors_manage' -or $failedIds -contains 'SEED-SPONSOR-PRIVATE') {
    $permissionItem = $script:Results | Where-Object Id -eq 'PERMISSION-PRESIDENT-sponsors_manage' | Select-Object -First 1
    $createItem = $script:Results | Where-Object Id -eq 'SEED-SPONSOR-PRIVATE' | Select-Object -First 1
    $reportLines.Add("- MEDIUM — El presidente no puede gestionar patrocinadores: $($permissionItem.Actual); creación: $($createItem.Actual). El borrador 050 añade el permiso faltante.")
}
if ($failedIds -contains 'SEED-NOTIFICATION-all_members' -or $failedIds -contains 'SEED-NOTIFICATION-managers') {
    $item = $script:Results | Where-Object { $_.Id -in @('SEED-NOTIFICATION-all_members','SEED-NOTIFICATION-managers') -and $_.State -eq 'FAIL' } | Select-Object -First 1
    $reportLines.Add("- MEDIUM — El presidente no pudo crear notificaciones por la ruta REST usada por `NotificationRepository`: $($item.Actual). Las pruebas de visibilidad y entregas dependientes quedan BLOQUEADAS; revisar RLS antes de alterar políticas.")
}
$openPolicy = $script:Results | Where-Object Id -eq 'CAT-OPEN-POLICIES' | Select-Object -First 1
if ($openPolicy) { $reportLines.Add("- LOW / OBSERVACION — $($openPolicy.Actual). La política abierta permite a usuarios autenticados leer el catálogo de permisos; esta consulta no observó datos de clubes.") }
$definerReview = $script:Results | Where-Object Id -eq 'CAT-DEFINER-REVIEW' | Select-Object -First 1
if ($definerReview) { $reportLines.Add("- REVISION PENDIENTE — $($definerReview.Actual). La detección textual no prueba por sí sola una vulnerabilidad; revisar cada definición y sus llamadas.") }
if ($failedIds.Count -eq 0) { $reportLines.Add('- No se registraron pruebas FAIL en esta ejecución.') }
$reportLines.Add('')
$reportLines.Add('## Usuarios de prueba que requieren borrado manual')
$reportLines.Add('El runner no conserva contrasenas ni tokens. Borrar estas cuentas en Authentication > Users; todos los registros de negocio usados por estas pruebas tienen prefijo `qa-` y fecha.')
foreach ($email in $script:QaUsers) { $reportLines.Add("- $email") }
$reportLines.Add('- QA creados en la ejecucion exploratoria previa: qa-20261007000546@example.com; qa-20261007000707@example.com; qa-20261007000809@example.com.')
$reportLines.Add('- Primera ejecucion del runner: qa-20261007-001615-president-a@example.com; qa-20261007-001615-president-b@example.com; qa-20261007-001615-treasurer@example.com; qa-20261007-001615-secretary@example.com; qa-20261007-001615-coach@example.com.')
$reportLines.Add('- Ejecucion anterior del runner: qa-20261007-002552-president-a@example.com; qa-20261007-002552-president-b@example.com; qa-20261007-002552-treasurer@example.com; qa-20261007-002552-secretary@example.com; qa-20261007-002552-coach@example.com.')
$reportLines.Add('- Ejecucion previa del runner: qa-20261007-002940-president-a@example.com; qa-20261007-002940-president-b@example.com; qa-20261007-002940-treasurer@example.com; qa-20261007-002940-secretary@example.com; qa-20261007-002940-coach@example.com.')
$reportLines.Add('')
$reportLines.Add('## Datos QA creados en esta ejecucion')
foreach ($club in @($script:ClubA, $script:ClubB)) {
    if ($club) { $reportLines.Add("- Club $($club.Slug): id=$($club.Id)") }
}
foreach ($fixtureSet in @(
    @{ Label='club A'; Data=$script:QaContent }
    @{ Label='club B'; Data=$script:QaContentB }
)) {
    if ($fixtureSet.Data) {
        foreach ($key in ($fixtureSet.Data.Keys | Sort-Object)) {
            $value = [string]$fixtureSet.Data[$key]
            if ($value -match '^[0-9a-fA-F-]{36}$') { $reportLines.Add("- $($fixtureSet.Label) $key`: $value") }
        }
    }
}
$reportLines.Add('')
$reportLines.Add('## Acciones manuales')
$reportLines.Add('- Revisar la lista de funciones SECURITY DEFINER reportada por `CAT-DEFINER-REVIEW` y confirmar que las RPC públicas solo exponen los campos esperados.')
$reportLines.Add('- Borrar las cuentas QA indicadas y, si se requiere limpieza de contenido, filtrar exclusivamente por el prefijo `qa-` y el sello temporal de cada ejecucion.')
$reportLines.Add('- Si se necesita validar un sorteo pagado, revisar y ejecutar manualmente `docs/sql/qa_seed.sql` en una transacción; el archivo solo inserta un ticket QA y no fue ejecutado.')
$reportLines.Add('- Revisar/aplicar manualmente `docs/sql/050_draft.sql` despues de validar los hallazgos; no se aplico desde este runner.')
$reportLines.Add('- Investigar por qué la inserción de notificaciones falla aunque la consulta autenticada de `is_club_manager` da true; no cambiar la política sin reproducir y encontrar la causa.')
$reportLines.Add('- Probar manualmente el flujo visual Flutter Web en incógnito; no se automatizó navegador.')
$reportLines | Set-Content -LiteralPath $reportPath -Encoding UTF8
Write-Host "Report=$reportPath"

if (($script:Results | Where-Object State -eq 'FAIL').Count -gt 0) { exit 1 }
exit 0
