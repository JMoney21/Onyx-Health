import './styles.css';
import type { Metadata } from 'next';
export const metadata: Metadata = { title: 'ONYX Health', description: 'Thoughtful primary care, family health, and wellness support. Discover a better kind of everyday care with Onyx Health.' };
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}
