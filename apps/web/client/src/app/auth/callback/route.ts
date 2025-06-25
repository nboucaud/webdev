import { client } from '@/utils/analytics/server';
import { createClient } from '@/utils/supabase/server';
import type { User } from '@onlook/db';
import { NextResponse } from 'next/server';
import { api } from '~/trpc/server';

export async function GET(request: Request) {
    const { searchParams, origin } = new URL(request.url);
    const code = searchParams.get('code');
    // if "next" is in param, use it as the redirect URL
    let next = searchParams.get('next') ?? '/';
    if (!next.startsWith('/')) {
        // if "next" is not a relative URL, use the default
        next = '/';
    }
    console.log({ Code: `Code: ${code}` });
    const forwardedHost = request.headers.get('x-forwarded-host'); // original origin before load balancer
    if (code) {
        const supabase = await createClient();
        const { error, data } = await supabase.auth.exchangeCodeForSession(code);
        console.log('Session exchange result:', {
            hasError: !!error,
            errorMessage: error?.message,
            hasUser: !!data?.user,
            hasSession: !!data?.session,
        });
        if (!error) {
            const isLocalEnv = process.env.NODE_ENV === 'development';
            if (isLocalEnv) {
                // we can be sure that there is no load balancer in between, so no need to watch for X-Forwarded-Host
                return NextResponse.redirect(`${origin}${next}`);
            } else if (forwardedHost) {
                return NextResponse.redirect(`http://${forwardedHost}${next}`);
            } else {
                return NextResponse.redirect(`${origin}${next}`);
            }
        }
        console.error({ error: error });
    }
    const redirectUrl = forwardedHost
        ? `http://${forwardedHost}/auth/auth-code-error`
        : `${origin}/auth/auth-code-error`;
    // return the user to an error page with instructions
    return NextResponse.redirect(redirectUrl);
}

async function getOrCreateUser(userId: string): Promise<User> {
    const user = await api.user.getById(userId);
    if (!user) {
        console.log(`User ${userId} not found, creating...`);
        const newUser = await api.user.create({ id: userId });
        return newUser;
    }
    console.log(`User ${userId} found, returning...`);
    return user;
}

function trackUserSignedIn(userId: string, properties: Record<string, any>) {
    try {
        if (!client) {
            console.warn('PostHog client not found, skipping user signed in tracking');
            return;
        }
        client.identify({
            distinctId: userId,
            properties: {
                ...properties,
                $set_once: {
                    signup_date: new Date().toISOString(),
                },
            },
        });
        client.capture({ event: 'user_signed_in', distinctId: userId });
    } catch (error) {
        console.error('Error tracking user signed in:', error);
    }
}
