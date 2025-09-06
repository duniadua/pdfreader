
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

export function Pricing() {
  return (
    <section id="pricing" className="w-full py-12 md:py-24 lg:py-32">
      <div className="container px-4 md:px-6">
        <div className="flex flex-col items-center justify-center space-y-4 text-center">
          <div className="space-y-2">
            <div className="inline-block rounded-lg bg-gray-100 px-3 py-1 text-sm dark:bg-gray-800">
              Pricing
            </div>
            <h2 className="text-3xl font-bold tracking-tighter sm:text-5xl">
              Choose Your Plan
            </h2>
            <p className="max-w-[900px] text-gray-500 md:text-xl/relaxed lg:text-base/relaxed xl:text-xl/relaxed dark:text-gray-400">
              We offer flexible pricing plans to fit your needs.
            </p>
          </div>
        </div>
        <div className="mx-auto grid max-w-5xl items-start gap-6 py-12 lg:grid-cols-3 lg:gap-12">
          <Card>
            <CardHeader>
              <CardTitle>Basic</CardTitle>
              <CardDescription>
                For small businesses and startups.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="text-4xl font-bold">$49/mo</div>
              <ul className="space-y-2 text-sm text-gray-500 dark:text-gray-400">
                <li>AI-Powered Automation</li>
                <li>Basic Data Analysis</li>
                <li>Email Support</li>
              </ul>
            </CardContent>
            <CardFooter>
              <Button className="w-full">Choose Plan</Button>
            </CardFooter>
          </Card>
          <Card className="border-2 border-primary">
            <CardHeader>
              <CardTitle>Pro</CardTitle>
              <CardDescription>
                For growing businesses.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="text-4xl font-bold">$99/mo</div>
              <ul className="space-y-2 text-sm text-gray-500 dark:text-gray-400">
                <li>Everything in Basic</li>
                <li>Advanced Data Analysis</li>
                <li>Priority Support</li>
              </ul>
            </CardContent>
            <CardFooter>
              <Button className="w-full">Choose Plan</Button>
            </CardFooter>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle>Enterprise</CardTitle>
              <CardDescription>
                For large-scale deployments.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="text-4xl font-bold">Contact Us</div>
              <ul className="space-y-2 text-sm text-gray-500 dark:text-gray-400">
                <li>Everything in Pro</li>
                <li>Custom AI Models</li>
                <li>Dedicated Account Manager</li>
              </ul>
            </CardContent>
            <CardFooter>
              <Button className="w-full">Contact Us</Button>
            </CardFooter>
          </Card>
        </div>
      </div>
    </section>
  );
}
