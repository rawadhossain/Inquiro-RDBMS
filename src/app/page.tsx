"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { authClient } from "@/lib/auth-client";
import HeroSection from "@/components/landing/hero-section";
import FeaturesSection from "@/components/landing/features";
import FAQs from "@/components/landing/faq";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import PublicSurveysPage from "./(app)/surveys/public/page";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Construction, Clock, ArrowLeft } from "lucide-react";
import { Badge } from "@/components/ui/badge";

export default function Home() {
	const router = useRouter();

	const { data: session, isLoading } = useQuery({
		queryKey: ["session"],
		queryFn: async () => {
			const result = await authClient.getSession();
			return result;
		},
	});

	const user = session?.data?.user as any;
	const isAuthenticated = !!session?.data?.session;

	useEffect(() => {
		if (!isLoading && isAuthenticated && user) {
			if (user.role === "CREATOR") {
				router.push("/dashboard");
			} else if (user.role === "RESPONDENT") {
				router.push("/respondent");
			}
		}
	}, [isAuthenticated, user, isLoading, router]);

	if (!isAuthenticated) {
		return (
			<main>
				<Button asChild size="lg" className="rounded-xl px-5 text-base">
					<Link href="/signup">
						<span className="text-nowrap">Get Started</span>
					</Link>
				</Button>

				{/* <HeroSection />
			<FeaturesSection />
			<FAQs /> */}

				<div className="flex-1 space-y-6 p-8 pt-6">
					{/* Header */}
					<div className="flex items-center space-x-2">
						<div>
							<p className="text-muted-foreground">
								This section is currently under development
							</p>
						</div>
					</div>

					{/* Under Construction Card */}
					<div className="flex justify-center items-center min-h-[60vh]">
						<Card className="max-w-lg w-full text-center">
							<CardHeader>
								<div className="flex justify-center mb-4">
									<Construction className="h-12 w-12 text-muted-foreground" />
								</div>

								<CardTitle className="text-2xl">Page Under Construction</CardTitle>

								<CardDescription className="mt-2">
									This feature is under work and will be available in the next
									phase.
								</CardDescription>
							</CardHeader>

							<CardContent className="space-y-6">
								<div className="flex justify-center">
									<Badge variant="outline" className="flex items-center gap-2">
										<Clock className="h-3 w-3" />
										Coming Soon
									</Badge>
								</div>
							</CardContent>
						</Card>
					</div>
				</div>
			</main>
		);
	}

	return null;
}
