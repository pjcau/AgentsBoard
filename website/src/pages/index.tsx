import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero', styles.heroBanner)}>
      <div className="container">
        <img src="/AgentsBoard/img/logo.svg" alt="AgentsBoard Logo" style={{width: 120, height: 120, marginBottom: 24}} />
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--primary button--lg"
            to="/docs/getting-started">
            Get Started
          </Link>
          <Link
            className="button button--secondary button--lg"
            style={{marginLeft: 12}}
            href="https://github.com/pjcau/AgentsBoard">
            GitHub
          </Link>
        </div>
      </div>
    </header>
  );
}

const features = [
  {
    title: 'Multi-Agent Orchestration',
    icon: '🎛️',
    description: 'Run Claude Code, Codex, Aider, and Gemini side by side. Monitor state, costs, and output from a single dashboard.',
  },
  {
    title: 'Metal GPU Rendering',
    icon: '⚡',
    description: 'Native Metal rendering with glyph atlas, viewport scissoring, and triple-buffered vertices for sub-4ms frame times.',
  },
  {
    title: 'SOLID Architecture',
    icon: '🏗️',
    description: 'Protocol-first design with ISP, DIP, OCP enforced across every module. Fully testable with 180+ unit tests.',
  },
  {
    title: 'Cost Tracking',
    icon: '💰',
    description: 'Per-token cost aggregation from session to project to fleet level. Real-time burn rate and alert thresholds.',
  },
  {
    title: 'MCP Server',
    icon: '🔌',
    description: 'JSON-RPC 2.0 Model Context Protocol server. Integrate with external tools via 5 built-in MCP tools.',
  },
  {
    title: 'Session Recording',
    icon: '🎬',
    description: 'Record sessions in Asciicast v2 format. Playback with variable speed, timeline, and event markers.',
  },
];

function Feature({title, icon, description}: {title: string; icon: string; description: string}) {
  return (
    <div className={clsx('col col--4')} style={{marginBottom: 24}}>
      <div className="feature-card" style={{height: '100%'}}>
        <div style={{fontSize: 36, marginBottom: 12}}>{icon}</div>
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title="AI Agent Mission Control"
      description="Native macOS app for orchestrating Claude Code, Codex, Aider & Gemini agents">
      <HomepageHeader />
      <main>
        <section style={{padding: '48px 0'}}>
          <div className="container">
            <div className="row">
              {features.map((props, idx) => (
                <Feature key={idx} {...props} />
              ))}
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
