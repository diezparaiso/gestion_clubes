// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Exportación completa de gestión del club a Excel.
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;
import '../../../core/services/supabase_service.dart';
import '../../finance/data/repositories/finance_repository.dart';
import '../../members/data/repositories/member_repository.dart';
import '../../teams/data/repositories/team_repository.dart';
import '../../players/data/repositories/player_repository.dart';
import '../../players/domain/entities/player.dart';

class PlayerExportRow {
  const PlayerExportRow({required this.team, required this.player});
  final String team;
  final Player player;
}

class ClubExportService {
  Future<void> exportClub({required String clubId, required String clubName}) async {
    final workbook = Excel.createExcel();
    workbook.delete('Sheet1');

    if (!SupabaseService.isConfigured) {
      final finance = await FinanceRepository().listTransactions(clubId);
      final members = await MemberRepository().listMembers(clubId);
      final teams = await TeamRepository().listTeams(clubId);
      final players = <PlayerExportRow>[];
      for (final team in teams) {
        final teamPlayers = await PlayerRepository().listTeamPlayers(team.id);
        for (final player in teamPlayers) {
          players.add(PlayerExportRow(team: team.name, player: player));
        }
      }
      _writeSheet(workbook, 'Resumen', [
        ['Club', clubName],
        ['Fecha de exportación', DateTime.now().toIso8601String()],
        ['Modo', 'Datos de demostración'],
      ]);
      _writeSheet(workbook, 'Tesorería', [
        ['ID', 'Tipo', 'Categoría', 'Importe', 'Descripción', 'Fecha'],
        ...finance.map((t) => [t.id, t.type.name, t.category, t.amount, t.description, t.date.toIso8601String()]),
      ]);
      _writeSheet(workbook, 'Socios', [
        ['Número', 'Nombre', 'Email', 'Estado', 'Tipo', 'Alta', 'Renovación', 'Baja', 'Dirección', 'CP', 'Ciudad', 'Provincia', 'País', 'Notas'],
        ...members.map((m) => [m.memberNumber, m.name, m.email, m.status.name, m.membershipType.name, m.joinDate.toIso8601String(), m.renewalDate?.toIso8601String() ?? '', m.leaveDate?.toIso8601String() ?? '', m.address ?? '', m.postalCode ?? '', m.city ?? '', m.province ?? '', m.country, m.notes ?? '']),
      ]);
      _writeSheet(workbook, 'Equipos', [
        ['ID', 'Equipo', 'Categoría', 'Temporada', 'Activo'],
        ...teams.map((t) => [t.id, t.name, t.category, t.seasonName, t.isActive]),
      ]);
      _writeSheet(workbook, 'Jugadores', [
        ['Equipo', 'ID', 'Nombre', 'Dorsal', 'Activo', 'Teléfono', 'Responsable', 'Teléfono responsable', 'Email responsable', 'Relación'],
        ...players.map((p) => [p.team, p.player.id, p.player.name, p.player.jerseyNumber ?? '', p.player.isActive, p.player.phone ?? '', p.player.guardianName ?? '', p.player.guardianPhone ?? '', p.player.guardianEmail ?? '', p.player.guardianRelationship ?? '']),
      ]);
      _writeSheet(workbook, 'Noticias', [['Sin datos en modo demostración']]);
      _writeSheet(workbook, 'Eventos', [['Sin datos en modo demostración']]);
      _writeSheet(workbook, 'Rifas', [['Sin datos en modo demostración']]);
    } else {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client.from('clubs').select('id, public_name, slug, website, instagram_url, facebook_url, youtube_url').eq('id', clubId).single(),
        client.from('financial_transactions').select('id, type, category, amount, description, transaction_date, account_id, created_by').eq('club_id', clubId).order('transaction_date', ascending: false),
        client.from('memberships').select('id, member_number, membership_type, status, join_date, renewal_date, leave_date, notes, address, postal_code, city, province, country, profiles!inner(first_name, last_name, email)').eq('club_id', clubId).order('member_number'),
        client.from('teams').select('id, name, category, is_active, season_id, seasons!inner(name, start_date)').eq('club_id', clubId).order('name'),
        client.from('team_players').select('id, team_id, player_id, jersey_number, is_active, players!inner(phone, guardian_name, guardian_phone, guardian_email, guardian_relationship, profiles!inner(first_name, last_name, email))').eq('club_id', clubId).order('jersey_number'),
        client.from('news').select('*').eq('club_id', clubId),
        client.from('events').select('*').eq('club_id', clubId),
        client.from('raffles').select('*').eq('club_id', clubId),
      ]);

      _writeSheet(workbook, 'Resumen', [
        ['Campo', 'Valor'],
        ['Club', clubName],
        ['Exportado', DateTime.now().toIso8601String()],
      ]);
      _writeMapSheet(workbook, 'Tesorería', (results[1] as List).cast<Map<String, dynamic>>());
      _writeMapSheet(workbook, 'Socios', (results[2] as List).cast<Map<String, dynamic>>());
      _writeMapSheet(workbook, 'Equipos', (results[3] as List).cast<Map<String, dynamic>>());
      _writeMapSheet(workbook, 'Jugadores', (results[4] as List).cast<Map<String, dynamic>>());
      _writeMapSheet(workbook, 'Noticias', (results[5] as List).cast<Map<String, dynamic>>());
      _writeMapSheet(workbook, 'Eventos', (results[6] as List).cast<Map<String, dynamic>>());
      _writeMapSheet(workbook, 'Rifas', (results[7] as List).cast<Map<String, dynamic>>());
    }

    final bytes = workbook.encode();
    if (bytes == null) throw StateError('No se pudo generar el archivo Excel.');
    final safeClubName = clubName.replaceAll(RegExp(r'[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ _-]'), '_').trim();
    final fileName = 'gestion_${safeClubName.isEmpty ? 'club' : safeClubName}_${DateTime.now().toIso8601String().substring(0, 10)}.xlsx';
    final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)..download = fileName..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  void _writeSheet(Excel workbook,String name,List<List<Object?>> rows){ final sheet=workbook[name]; for(final row in rows){ sheet.appendRow(row.map((v)=>TextCellValue(v?.toString()??'')).toList()); } }
  void _writeMapSheet(Excel workbook,String name,List<Map<String,dynamic>> rows){ if(rows.isEmpty){_writeSheet(workbook,name,[['Sin datos']]);return;} final keys=rows.expand((r)=>r.keys).toSet().toList(); _writeSheet(workbook,name,[keys,...rows.map((r)=>keys.map((k){final v=r[k];return v is Map || v is List ? jsonEncode(v) : v;}).toList())]); }
}