import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/config/env.dart';

/// Serves the local code-push dashboard (HTML). The admin token is injected so
/// the page's fetch calls can hit the guarded `/admin/*` endpoints.
Response onRequest(RequestContext context) {
  final page = _dashboardHtml
      .replaceAll('__ADMIN_TOKEN__', Env.adminToken)
      .replaceAll('__DEFAULT_APP__', Env.defaultAppId)
      .replaceAll('__DEFAULT_REL__', Env.defaultReleaseVersion)
      .replaceAll('__PUBLIC_URL__', Env.publicBaseUrl);
  return Response(
    body: page,
    headers: {HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8'},
  );
}

const _dashboardHtml = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>In-House Code Push</title>
<style>
  :root{--bg:#0d1117;--panel:#161b22;--border:#30363d;--text:#e6edf3;--muted:#8b949e;--accent:#1f6feb;--green:#2ea043;--red:#da3633;}
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);font:14px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif}
  header{padding:18px 28px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:11px}
  header h1{font-size:17px;margin:0;font-weight:650}
  header .dot{width:9px;height:9px;border-radius:50%;background:var(--green);box-shadow:0 0 8px var(--green)}
  header .tag{color:var(--muted);font-size:12px;margin-left:auto}
  .wrap{max-width:1000px;margin:0 auto;padding:24px 28px 70px}
  .card{background:var(--panel);border:1px solid var(--border);border-radius:12px;padding:20px;margin-bottom:20px}
  .card h2{margin:0 0 14px;font-size:12px;text-transform:uppercase;letter-spacing:.07em;color:var(--muted)}
  .active{display:flex;align-items:center;justify-content:space-between;gap:20px;flex-wrap:wrap}
  .active .num{font-size:34px;font-weight:700;line-height:1}
  .meta{color:var(--muted);font-size:13px}
  .urls code{background:#0b0f14;border:1px solid var(--border);padding:3px 8px;border-radius:6px;color:#79c0ff;display:inline-block;margin:2px 0}
  .row{display:flex;gap:12px;flex-wrap:wrap}
  label{display:block;font-size:12px;color:var(--muted);margin:0 0 4px}
  input{background:#0b0f14;border:1px solid var(--border);color:var(--text);border-radius:8px;padding:9px 11px;width:100%;font:inherit}
  .field{flex:1;min-width:120px;margin-bottom:12px}
  .drop{border:2px dashed var(--border);border-radius:10px;padding:22px;text-align:center;color:var(--muted);cursor:pointer;transition:.15s}
  .drop.over{border-color:var(--accent);color:var(--text);background:rgba(31,111,235,.08)}
  .drop b{color:var(--text)}
  button{background:var(--accent);color:#fff;border:0;border-radius:8px;padding:10px 18px;font:inherit;font-weight:600;cursor:pointer}
  button:disabled{opacity:.45;cursor:default}
  button.ghost{background:transparent;border:1px solid var(--border);color:var(--text);padding:5px 12px;font-weight:500}
  button.danger{border-color:rgba(218,54,51,.5);color:#f85149}
  table{width:100%;border-collapse:collapse;font-size:13px}
  th,td{text-align:left;padding:9px 10px;border-bottom:1px solid var(--border);vertical-align:top}
  th{color:var(--muted);font-weight:500;font-size:11px;text-transform:uppercase;letter-spacing:.05em}
  tr:last-child td{border-bottom:0}
  .badge{font-size:11px;padding:2px 9px;border-radius:20px;font-weight:600}
  .badge.on{background:rgba(46,160,67,.18);color:#3fb950}
  .badge.off{background:rgba(218,54,51,.16);color:#f85149}
  .mono{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
  #msg{padding:10px 14px;border-radius:8px;margin-top:12px;display:none}
  #msg.ok{display:block;background:rgba(46,160,67,.15);color:#3fb950}
  #msg.err{display:block;background:rgba(218,54,51,.15);color:#f85149}
  a{color:inherit;text-decoration:none}
</style>
</head>
<body>
<header><span class="dot"></span><h1>In-House Code Push</h1><span class="tag">self-hosted</span></header>
<div class="wrap">

  <div class="card">
    <h2>Active patch — what devices download now</h2>
    <div class="active">
      <div>
        <div class="num" id="activeNum">—</div>
        <div class="meta" id="activeMeta">No patch pushed yet</div>
        <a id="activeApk" href="#" download style="display:none;margin-top:12px"><button>📱 Download APK (install on device)</button></a>
      </div>
      <div class="urls">
        <div class="meta">Patch URL (devices fetch this):</div>
        <code>__PUBLIC_URL__/libapp.so</code><br/>
        <div class="meta" style="margin-top:6px">Android emulator &rarr; host:</div>
        <code>http://10.0.2.2:8080/libapp.so</code>
      </div>
    </div>
  </div>

  <div class="card">
    <h2>Build &amp; push from a branch</h2>
    <div class="row" style="align-items:flex-end">
      <div class="field" style="flex:2;margin-bottom:0"><label>Branch</label>
        <div style="position:relative">
          <input id="branch" autocomplete="off" placeholder="type to search branches…" style="background:#0b0f14;border:1px solid var(--border);color:var(--text);border-radius:8px;padding:9px 11px;width:100%;font:inherit"/>
          <div id="branchMenu" style="display:none;position:absolute;z-index:30;left:0;right:0;top:calc(100% + 4px);max-height:240px;overflow:auto;background:#0b0f14;border:1px solid var(--border);border-radius:8px;box-shadow:0 8px 24px rgba(0,0,0,.5)"></div>
        </div>
      </div>
      <button id="refreshBranches" class="ghost">&#8635;</button>
      <button id="build">&#128296; Build &amp; push</button>
    </div>
    <div id="buildStatus" class="meta" style="margin-top:10px"></div>
    <pre id="buildLog" style="display:none;background:#0b0f14;border:1px solid var(--border);border-radius:8px;padding:10px;margin-top:8px;max-height:220px;overflow:auto;font-size:11px;line-height:1.45;color:#8b949e;white-space:pre-wrap"></pre>
  </div>

  <div class="card">
    <h2>Push a new update</h2>
    <div class="drop" id="drop">Drop a <b>libapp.so</b> here, or <b>click to choose</b>
      <div class="meta" id="fileHint" style="margin-top:6px">No file selected</div>
    </div>
    <input type="file" id="file" accept=".so" style="display:none"/>
    <div class="row" style="margin-top:14px">
      <div class="field"><label>App ID</label><input id="app_id" value="__DEFAULT_APP__"/></div>
      <div class="field"><label>Release version</label><input id="release_version" value="__DEFAULT_REL__"/></div>
      <div class="field" style="max-width:110px"><label>Patch #</label><input id="number" type="number" value="1"/></div>
    </div>
    <div class="row">
      <div class="field"><label>Platform</label><input id="platform" value="android"/></div>
      <div class="field"><label>Arch</label><input id="arch" value="arm64"/></div>
      <div class="field"><label>Channel</label><input id="channel" value="stable"/></div>
      <div class="field" style="max-width:120px"><label>Rollout %</label><input id="rollout" type="number" value="100"/></div>
    </div>
    <button id="push" disabled>🚀 Push update</button>
    <div id="msg"></div>
  </div>

  <div class="card">
    <h2>Devices — live adoption</h2>
    <div id="adoption" class="meta">No check-ins yet — launch the app.</div>
    <table style="margin-top:10px">
      <thead><tr><th>Device</th><th>Release</th><th>On patch</th><th>Last seen</th></tr></thead>
      <tbody id="deviceRows"></tbody>
    </table>
  </div>

  <div class="card">
    <h2>All patches</h2>
    <table>
      <thead><tr><th>#</th><th>Release</th><th>Size</th><th>SHA-256</th><th>Signed</th><th>Status</th><th></th></tr></thead>
      <tbody id="rows"><tr><td colspan="7" class="meta">Loading…</td></tr></tbody>
    </table>
  </div>

</div>
<script>
const TOKEN="__ADMIN_TOKEN__";
const H={"Authorization":"Bearer "+TOKEN};
const $=id=>document.getElementById(id);
const fmtSize=b=>!b?"—":b>=1048576?(b/1048576).toFixed(1)+" MB":(b/1024).toFixed(0)+" KB";
function msg(t,ok){const m=$("msg");m.textContent=t;m.className=ok?"ok":"err";}

async function load(){
  try{
    const r=await fetch("/admin/patches",{headers:H});
    const d=await r.json();
    render(d.patches||[]);
  }catch(e){$("rows").innerHTML='<tr><td colspan=7 style="color:#f85149">Failed to load: '+e+'</td></tr>';}
}

function render(patches){
  const live=patches.filter(p=>!p.rolled_back).sort((a,b)=>b.number-a.number);
  const active=live[0];
  if(active){
    $("activeNum").textContent="#"+active.number;
    $("activeMeta").innerHTML=active.release_version+" · "+fmtSize(active.size_bytes)+
      " · <span class=mono>"+active.hash.slice(0,12)+"…</span>"+(active.hash_signature?" · signed":"");
    const apk=$("activeApk");apk.href="/apk/"+active.storage_key.replace(".vmcode",".apk");apk.style.display="inline-block";
  }else{$("activeNum").textContent="—";$("activeMeta").textContent="No patch pushed yet";$("activeApk").style.display="none";}

  const maxN=patches.reduce((m,p)=>Math.max(m,p.number),0);
  if(document.activeElement!==$("number")) $("number").value=maxN+1;

  const sorted=[...patches].sort((a,b)=>b.number-a.number);
  $("rows").innerHTML=sorted.length?sorted.map(p=>{
    const isActive=active&&p.number===active.number&&p.release_version===active.release_version;
    const status=p.rolled_back?'<span class="badge off">rolled back</span>'
      :isActive?'<span class="badge on">● live</span>':'<span class="meta">idle</span>';
    const action=p.rolled_back
      ?`<button class="ghost" onclick="setRb(${p.number},'${p.release_version}',false)">Restore</button>`
      :`<button class="ghost danger" onclick="setRb(${p.number},'${p.release_version}',true)">Roll back</button>`;
    return `<tr>
      <td><b>#${p.number}</b></td>
      <td>${p.release_version}<div class="meta">${p.platform}/${p.arch} · ${p.channel}</div></td>
      <td>${fmtSize(p.size_bytes)}</td>
      <td class="mono">${p.hash.slice(0,10)}…</td>
      <td>${p.hash_signature?"✓":"—"}</td>
      <td>${status}</td>
      <td style="text-align:right;white-space:nowrap"><a href="/apk/${p.storage_key.replace('.vmcode','.apk')}" download><button class="ghost">📱 APK</button></a> ${action}</td>
    </tr>`;
  }).join(""):'<tr><td colspan=7 class="meta">No patches yet — push one above.</td></tr>';
}

async function setRb(number,release,val){
  await fetch("/admin/rollback",{method:"POST",headers:{...H,"Content-Type":"application/json"},
    body:JSON.stringify({app_id:$("app_id").value,release_version:release,platform:$("platform").value,arch:$("arch").value,channel:$("channel").value,number,rolled_back:val})});
  load();
}

$("drop").onclick=()=>$("file").click();
$("file").onchange=e=>pick(e.target.files[0]);
["dragover","dragenter"].forEach(ev=>$("drop").addEventListener(ev,e=>{e.preventDefault();$("drop").classList.add("over");}));
["dragleave","drop"].forEach(ev=>$("drop").addEventListener(ev,e=>{e.preventDefault();$("drop").classList.remove("over");}));
$("drop").addEventListener("drop",e=>{if(e.dataTransfer.files[0])pick(e.dataTransfer.files[0]);});
function pick(f){if(!f)return;window._file=f;$("fileHint").innerHTML="Selected: <b>"+f.name+"</b> ("+fmtSize(f.size)+")";$("push").disabled=false;}

$("push").onclick=async()=>{
  const f=window._file;if(!f){msg("Choose a libapp.so first",false);return;}
  $("push").disabled=true;msg("Uploading "+fmtSize(f.size)+"…",true);
  const fd=new FormData();
  fd.append("patch",f,f.name);
  fd.append("app_id",$("app_id").value);
  fd.append("release_version",$("release_version").value);
  fd.append("platform",$("platform").value);
  fd.append("arch",$("arch").value);
  fd.append("channel",$("channel").value);
  fd.append("number",$("number").value);
  fd.append("rollout_percentage",$("rollout").value);
  try{
    const r=await fetch("/admin/patches",{method:"POST",headers:H,body:fd});
    if(!r.ok){msg("Upload failed: "+r.status+" "+(await r.text()),false);$("push").disabled=false;return;}
    const d=await r.json();
    msg("✅ Pushed patch #"+d.registered.number+" — devices get it on next launch.",true);
    window._file=null;$("fileHint").textContent="No file selected";$("push").disabled=true;
    load();
  }catch(e){msg("Upload error: "+e,false);$("push").disabled=false;}
};

let ALL_BRANCHES=[];
function renderBranchMenu(q){
  const menu=$("branchMenu");
  const ql=(q||"").toLowerCase().trim();
  const matches=(ql?ALL_BRANCHES.filter(b=>b.toLowerCase().includes(ql)):ALL_BRANCHES).slice(0,60);
  if(!matches.length){menu.style.display="none";return;}
  menu.innerHTML=matches.map(b=>`<div class="bopt" data-b="${b}" style="padding:8px 11px;cursor:pointer;font-size:13px;border-bottom:1px solid var(--border)">${b}</div>`).join("");
  menu.querySelectorAll(".bopt").forEach(el=>{
    el.onmousedown=ev=>{ev.preventDefault();$("branch").value=el.dataset.b;menu.style.display="none";};
    el.onmouseenter=()=>el.style.background="rgba(31,111,235,.15)";
    el.onmouseleave=()=>el.style.background="";
  });
  menu.style.display="block";
}
async function loadBranches(){
  $("buildStatus").textContent="loading branches…";
  try{
    const r=await fetch("/admin/branches",{headers:H});
    const d=await r.json();
    ALL_BRANCHES=d.branches||[];
    $("buildStatus").textContent=ALL_BRANCHES.length+" branches — type to search, then build";
  }catch(e){$("buildStatus").textContent="failed to load branches: "+e;}
}
$("refreshBranches").onclick=loadBranches;
$("branch").addEventListener("input",ev=>renderBranchMenu(ev.target.value));
$("branch").addEventListener("focus",ev=>renderBranchMenu(ev.target.value));
$("branch").addEventListener("blur",()=>setTimeout(()=>{$("branchMenu").style.display="none";},150));
$("build").onclick=async()=>{
  const branch=$("branch").value;
  if(!branch) return;
  $("build").disabled=true;
  const r=await fetch("/admin/build",{method:"POST",headers:{...H,"Content-Type":"application/json"},body:JSON.stringify({branch})});
  if(!r.ok){const e=await r.json().catch(()=>({}));$("buildStatus").textContent="cannot start: "+(e.error||r.status);$("build").disabled=false;return;}
  $("buildLog").style.display="block";
  pollBuild();
};
async function pollBuild(){
  try{
    const r=await fetch("/admin/build",{headers:H});
    const d=await r.json();
    $("buildLog").textContent=d.log||"";
    $("buildLog").scrollTop=$("buildLog").scrollHeight;
    if(d.running){
      $("buildStatus").innerHTML="⏳ building <b>"+d.branch+"</b> + pushing… (a few minutes)";
      setTimeout(pollBuild,2000);
    }else{
      if(d.exit_code===0){$("buildStatus").innerHTML="✅ built <b>"+d.branch+"</b> and pushed a patch";load();}
      else{$("buildStatus").innerHTML="❌ build failed (exit "+d.exit_code+") — see log below";}
      $("build").disabled=false;
    }
  }catch(e){$("buildStatus").textContent="status error: "+e;$("build").disabled=false;}
}
function fmtAgo(iso){const s=Math.max(0,(Date.now()-new Date(iso).getTime())/1000);return s<60?Math.round(s)+"s ago":s<3600?Math.round(s/60)+"m ago":Math.round(s/3600)+"h ago";}
async function loadDevices(){
  try{
    const r=await fetch("/admin/devices",{headers:H});
    const d=(await r.json()).devices||[];
    const by={};d.forEach(x=>{const k=x.current_patch_number==null?"none":("#"+x.current_patch_number);by[k]=(by[k]||0)+1;});
    const summary=Object.keys(by).sort().map(k=>k+": <b>"+by[k]+"</b>").join(" · ");
    $("adoption").innerHTML=d.length?(d.length+" device"+(d.length>1?"s":"")+" checked in — "+summary):"No check-ins yet — launch the app.";
    $("deviceRows").innerHTML=d.map(x=>`<tr>
      <td class="mono">${x.client_id}</td>
      <td>${x.release_version}<div class="meta">${x.platform}/${x.arch}</div></td>
      <td>${x.current_patch_number==null?'<span class="meta">none</span>':'<b>#'+x.current_patch_number+'</b>'}</td>
      <td class="meta">${fmtAgo(x.last_seen)}</td>
    </tr>`).join("");
  }catch(e){$("adoption").textContent="failed to load devices: "+e;}
}
loadBranches();
load();
loadDevices();
setInterval(load,5000);
setInterval(loadDevices,5000);
</script>
</body>
</html>''';
