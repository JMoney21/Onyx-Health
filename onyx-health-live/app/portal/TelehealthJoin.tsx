"use client";
import {useEffect,useState} from "react";
import {Video,ArrowUpRight} from "lucide-react";
import {supabase} from "../../lib/supabase";
import {safeMeetingUrl} from "../../lib/telehealth";
export default function TelehealthJoin({appointment}:{appointment:any}){const [session,setSession]=useState<any>(null),[error,setError]=useState(false),[loading,setLoading]=useState(true),[refresh,setRefresh]=useState(0);
useEffect(()=>{let current=true;setSession(null);setLoading(true);setError(false);if(appointment.visit_mode!=="telehealth"){setLoading(false);return} (async()=>{const {data,error}=await supabase.from("telehealth_sessions").select("meeting_url,service_name,session_status").eq("appointment_id",appointment.id).eq("session_status","ready").maybeSingle();if(!current)return;setError(Boolean(error));setSession(data);setLoading(false)})();return()=>{current=false}},[appointment.id,appointment.visit_mode,refresh]);
if(appointment.visit_mode!=="telehealth"||['cancelled','completed'].includes(appointment.status))return null;const url=session?safeMeetingUrl(session.meeting_url):null;
return <div className="pp-telehealth-join"><span className="pp-eyebrow"><Video size={17}/> YOUR VIRTUAL VISIT</span>{loading?<p role="status">Checking video access…</p>:url?<><p>Your care team has opened access. Join using {session.service_name}.</p><a className="btn" href={url} target="_blank" rel="noopener noreferrer" referrerPolicy="no-referrer">Join video visit <ArrowUpRight size={17}/></a><p className="pp-fine">Allow camera and microphone access in the video service. Use a private space.</p></>:<p>{error?"Video access couldn’t load. Contact your care team if your visit is starting.":"Your join button will appear when the care team opens video access."}</p>}<button className="pp-link" onClick={()=>setRefresh(n=>n+1)} disabled={loading}>Refresh video access</button></div>;
}
