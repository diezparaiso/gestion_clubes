import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
const reply=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"Content-Type":"application/json"}});
Deno.serve(async req=>{
 if(req.method==="OPTIONS")return new Response("ok",{headers:cors});
 if(req.method!=="POST")return reply({error:"Método no permitido"},405);
 try{
  const url=Deno.env.get("SUPABASE_URL"),anon=Deno.env.get("SUPABASE_ANON_KEY"),key=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),stripe=Deno.env.get("STRIPE_SECRET_KEY"),app=Deno.env.get("PUBLIC_APP_URL");
  if(!url||!anon||!key||!stripe||!app)throw new Error("Faltan secretos de configuración.");
  const b=await req.json(),{clubSlug,raffleSlug,numbers,buyerName,buyerEmail,buyerPhone}=b;
  if(typeof clubSlug!=="string"||typeof raffleSlug!=="string"||!Array.isArray(numbers)||numbers.length<1||numbers.length>10||typeof buyerName!=="string"||typeof buyerEmail!=="string")return reply({error:"Datos de compra no válidos."},400);
  const pub=createClient(url,anon);
  const {error:re}=await pub.rpc("reserve_public_raffle_numbers",{target_club_slug:clubSlug,target_raffle_slug:raffleSlug,selected_numbers:numbers,target_buyer_name:buyerName,target_buyer_email:buyerEmail,target_buyer_phone:buyerPhone??null});
  if(re)throw new Error(re.message);
  const db=createClient(url,key);
  const {data:raffle,error:rf}=await db.from("raffles").select("id,club_id,title,ticket_price,clubs!inner(slug)").eq("slug",raffleSlug).eq("clubs.slug",clubSlug).single();
  if(rf||!raffle)throw new Error("No se ha podido validar la rifa.");
  const {data:tickets,error:te}=await db.from("raffle_tickets").select("id,number").eq("raffle_id",raffle.id).eq("payment_status","pending").in("number",numbers).eq("buyer_email",buyerEmail.trim().toLowerCase());
  if(te||!tickets||tickets.length!==numbers.length)throw new Error("La reserva no coincide con los números seleccionados.");
  const unit=Math.round(Number(raffle.ticket_price)*100),total=unit*tickets.length;
  if(!Number.isSafeInteger(total)||total<50)throw new Error("Importe no válido.");
  const p=new URLSearchParams({mode:"payment",success_url:app+"/pago/exito?session_id={CHECKOUT_SESSION_ID}",cancel_url:app+"/pago/cancelado",customer_email:buyerEmail.trim().toLowerCase(),"line_items[0][price_data][currency]":"eur","line_items[0][price_data][unit_amount]":String(unit),"line_items[0][price_data][product_data][name]":String(raffle.title),"line_items[0][quantity]":String(tickets.length),client_reference_id:raffle.id,"metadata[club_id]":raffle.club_id,"metadata[raffle_id]":raffle.id,"metadata[ticket_ids]":tickets.map(t=>t.id).join(",")});
  const res=await fetch("https://api.stripe.com/v1/checkout/sessions",{method:"POST",headers:{Authorization:"Bearer "+stripe,"Content-Type":"application/x-www-form-urlencoded"},body:p});
  const session=await res.json();if(!res.ok)throw new Error(session.error?.message??"Error creando Checkout.");
  return reply({url:session.url,sessionId:session.id});
 }catch(e){return reply({error:e instanceof Error?e.message:"Error al crear el pago."},400);}
});
