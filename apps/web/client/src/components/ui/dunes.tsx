import Image from 'next/image';

export function Dunes() {
    return (
        <div className="hidden w-full lg:block md:block m-6">
            <img
                className="w-full h-full object-cover rounded-xl hidden dark:flex"
                src={'https://webdev.infogito.com/assets/dunes-login-dark.png'}
                alt="Onlook dunes dark"
                width={1000}
                height={1000}
            />
            <img
                className="w-full h-full object-cover rounded-xl flex dark:hidden"
                src={'https://webdev.infogito.com/assets/dunes-login-light.png'}
                alt="Onlook dunes light"
                width={1000}
                height={1000}
            />
        </div>
    );
}
