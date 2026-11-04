export function safeMeetingUrl(value:string):string|null{
 try{const url=new URL(value.trim());if(url.protocol!=="https:"||url.username||url.password)return null;return url.href}catch{return null}
}
