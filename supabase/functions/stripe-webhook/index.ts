import Stripe from "https://esm.sh/stripe@17.7.0?target=deno";
import {createClient} from "https://esm.sh/@supabase/supabase-js@2";
const stripe=new Stripe(Deno.env.get("STRIPE_SECRET_KEY")??"",{apiVersion:"2025-02-24.acacia"});
const crypto=Stripe.createSubtleCryptoProvider();
Deno.serve(async req=>{
 if(req.method!=="POST")return new Response("Method not allowed",{status:405});
 const sig=req.headers.get("Stripe-Signature"),secret=Deno.env.get("STRIPE_WEBHOOK_SECRET");
 if(!sig||!secret)return new Response("Missing signature",{status:400});
 let event:Stripe.Event;
 try{event=await stripe.webhooks.constructEventAsync(await req.text(),sig,secret,undefined,crypto);}catch{return new Response("Invalid signature",{status:400});}
 const url=Deno.env.get("SUPABASE_URL"),key=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
 if(!url||!key)return new Response("Missing database config",{status:500});
 const db=createClient(url,key);
 try{
  if(event.type==="checkout.session.completed"||event.type==="checkout.session.async_payment_succeeded"){
   const s=event.data.object as Stripe.Checkout.Session;
   if(s.payment_status!=="paid")return new Response("Not paid",{status:200});
   const club=s.metadata?.club_id,raffleId=s.metadata?.raffle_id,ids=(s.metadata?.ticket_ids??"").split(",").filter(Boolean);
   if(!club||!raffleId||!ids.length||!s.amount_total)throw new Error("Metadata de pago incompleta.");
   const {data:r,error:er}=await db.from("raffles").select("id,club_id").eq("id",raffleId).single();
   if(er||r.club_id!==club)throw new Error("La rifa no corresponde al club.");
   const {data:t,error:te}=await db.from("raffle_tickets").select("id").in("id",ids).eq("raffle_id",raffleId).eq("club_id",club);
   if(te||!t||t.length!==ids.length)throw new Error("Las participaciones no coinciden.");
   const gross=s.amount_total/100;
   const {error:se}=await db.rpc("record_platform_sale",{target_club_id:club,target_source:"stripe_checkout",target_source_sale_id:s.id,target_gross_amount:gross,target_currency:(s.currency??"eur").toUpperCase(),target_payment_provider:"stripe",target_provider_payment_id:typeof s.payment_intent==="string"?s.payment_intent:null,target_metadata:{raffle_id:raffleId,ticket_ids:ids,checkout_session_id:s.id}});
   if(se)throw se;
   const {error:ue}=await db.from("raffle_tickets").update({payment_status:"paid",purchased_at:new Date().toISOString(),payment_reference:s.id,reservation_expires_at:null}).in("id",ids).eq("payment_status","pending");
   if(ue)throw ue;
   const commission=Math.round(gross*0.05*100)/100;
   const {error:pe}=await db.from("club_payouts").upsert({club_id:club,source:"stripe_checkout",source_sale_id:s.id,gross_amount:gross,platform_commission:commission,currency:"EUR",metadata:{checkout_session_id:s.id,payment_intent:s.payment_intent??null}}, {onConflict:"source,source_sale_id",ignoreDuplicates:true});
   if(pe)throw pe;
  }
  return new Response(JSON.stringify({received:true}),{status:200,headers:{"Content-Type":"application/json"}});
 }catch(e){return new Response(e instanceof Error?e.message:"Webhook error",{status:500});}
});
