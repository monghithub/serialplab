import { Router, Request, Response } from 'express';
import { serialize } from './serialization';
import { publish } from './broker';
import { saveMessage, getMessages } from './db';

const SERVICE_NAME = 'service-node';
const router = Router();

router.post('/publish/:target/:protocol/:broker', async (req: Request, res: Response) => {
  try {
    const target = req.params.target as string;
    const protocol = req.params.protocol as string;
    const broker = req.params.broker as string;
    const user = req.body;
    const data = serialize(protocol, user);
    await publish(broker, target, protocol, data, SERVICE_NAME);

    await saveMessage({
      direction: 'sent', protocol, broker, targetService: target,
      originService: SERVICE_NAME, rawPayload: data,
      userId: user.id, userName: user.name, userEmail: user.email, userTimestamp: user.timestamp,
    });

    res.json({ status: 'published', target, protocol, broker, bytes: data.length });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/messages', async (_req: Request, res: Response) => {
  try {
    const messages = await getMessages();
    res.json(messages);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
