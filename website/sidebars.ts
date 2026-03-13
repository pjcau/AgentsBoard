import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'getting-started',
    'installation',
    {
      type: 'category',
      label: 'Architecture',
      collapsed: false,
      items: [
        'architecture/overview',
        'architecture/solid-principles',
        'architecture/module-structure',
        'architecture/composition-root',
      ],
    },
    {
      type: 'category',
      label: 'Core Modules',
      items: [
        'core/agent-system',
        'core/terminal-engine',
        'core/fleet-management',
        'core/cost-tracking',
        'core/config-system',
        'core/recording',
        'core/mcp-server',
        'core/orchestration',
        'core/context-bridge',
      ],
    },
    {
      type: 'category',
      label: 'UI Components',
      items: [
        'ui/command-palette',
        'ui/diff-review',
        'ui/editor',
        'ui/file-explorer',
        'ui/mermaid-renderer',
        'ui/theme-engine',
      ],
    },
    {
      type: 'category',
      label: 'API Reference',
      items: [
        'api/core-protocols',
        'api/agent-protocols',
        'api/fleet-protocols',
        'api/mcp-tools',
      ],
    },
    {
      type: 'category',
      label: 'CLI',
      items: [
        'cli/agentsctl',
      ],
    },
    'contributing',
    'roadmap',
  ],
};

export default sidebars;
