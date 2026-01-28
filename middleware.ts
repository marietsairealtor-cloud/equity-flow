import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(req: NextRequest) {
  // Block /app/debug in production
  if (process.env.NODE_ENV === 'production' && req.nextUrl.pathname.startsWith('/app/debug')) {
    return new NextResponse('Not Found', { status: 404 });
  }
  return NextResponse.next();
}

export const config = {
  matcher: ['/app/:path*'],
};