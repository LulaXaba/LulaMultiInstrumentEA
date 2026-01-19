export default function Header({ metrics }: { metrics?: any }) {
    return (
        <header className="bg-terminal-darker border-b border-terminal-grid px-4 py-2 flex items-center justify-between">
            {/* Logo / Title */}
            <div className="flex items-center space-x-4">
                <div className="text-terminal-green text-lg font-bold tracking-wider glow-green">
                    ⚡ ML-LITE // PROTOCOL
                </div>
                <div className="text-terminal-gray text-[10px]">
                    v.7.3.0 DELTA // HIGH FREQUENCY
                </div>
            </div>

            {/* System stats */}
            <div className="flex items-center space-x-6 text-[10px]">
                <div>
                    <span className="text-terminal-gray">LATENCY:</span>
                    <span className="text-terminal-green ml-2">12ms</span>
                </div>
                <div>
                    <span className="text-terminal-gray">UPTIME:</span>
                    <span className="text-white ml-2">48:12:09</span>
                </div>
                <div>
                    <span className="text-terminal-gray">MEMORY:</span>
                    <span className="text-white ml-2">4.2GB / 16GB</span>
                </div>

                {/* System status */}
                <div className="flex items-center space-x-2">
                    <div className="w-2 h-2 bg-terminal-green rounded-full animate-pulse"></div>
                    <span className="text-terminal-green uppercase font-bold">SYSTEM OPTIMAL</span>
                </div>
            </div>
        </header>
    );
}
