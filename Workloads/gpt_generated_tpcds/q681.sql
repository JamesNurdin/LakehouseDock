WITH channel_profit AS (
    -- Store sales profit per month and promotion
    SELECT d.d_year,
           d.d_month_seq,
           p.p_promo_name,
           SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, p.p_promo_name

    UNION ALL

    -- Store returns (negative impact) per month and promotion
    SELECT d.d_year,
           d.d_month_seq,
           p.p_promo_name,
           -SUM(sr.sr_net_loss) AS net_profit
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, p.p_promo_name

    UNION ALL

    -- Catalog sales profit per month and promotion
    SELECT d.d_year,
           d.d_month_seq,
           p.p_promo_name,
           SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, p.p_promo_name

    UNION ALL

    -- Catalog returns (negative impact) per month and promotion
    SELECT d.d_year,
           d.d_month_seq,
           p.p_promo_name,
           -SUM(cr.cr_net_loss) AS net_profit
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, p.p_promo_name

    UNION ALL

    -- Web sales profit per month and promotion
    SELECT d.d_year,
           d.d_month_seq,
           p.p_promo_name,
           SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, p.p_promo_name

    UNION ALL

    -- Web returns (negative impact) per month and promotion
    SELECT d.d_year,
           d.d_month_seq,
           p.p_promo_name,
           -SUM(wr.wr_net_loss) AS net_profit
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, p.p_promo_name
)
SELECT cp.d_year,
       cp.d_month_seq,
       cp.p_promo_name,
       SUM(cp.net_profit) AS total_net_profit
FROM channel_profit cp
GROUP BY cp.d_year, cp.d_month_seq, cp.p_promo_name
HAVING SUM(cp.net_profit) <> 0
ORDER BY cp.d_year,
         cp.d_month_seq,
         total_net_profit DESC
LIMIT 20
