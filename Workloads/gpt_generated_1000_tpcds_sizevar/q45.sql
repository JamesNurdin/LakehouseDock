WITH base AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        p.p_channel_radio,
        ca.ca_city,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_net_loss
    FROM time_dim td
    JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE s.s_market_manager IN ('John Sizemore', 'David Smith')
      AND s.s_hours = '8AM-8AM'
      AND p.p_channel_radio = 'N'
      AND ca.ca_city IN ('Glendale', 'Oakland')
      AND p.p_start_date_sk >= 2450350
),
store_avg AS (
    SELECT s_store_sk, AVG(ss_net_profit) AS store_avg_profit
    FROM base
    GROUP BY s_store_sk
),
agg AS (
    SELECT
        b.s_store_name,
        b.p_channel_radio,
        b.ca_city,
        b.s_store_sk,
        SUM(b.ss_net_paid) AS total_net_paid,
        SUM(b.sr_net_loss) AS total_net_loss,
        AVG(b.ss_net_profit) AS avg_net_profit,
        CASE WHEN SUM(b.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM base b
    GROUP BY ROLLUP (b.s_store_name, b.p_channel_radio, b.ca_city, b.s_store_sk)
)
SELECT
    a.s_store_name,
    a.p_channel_radio,
    a.ca_city,
    a.total_net_paid,
    a.total_net_loss,
    a.avg_net_profit,
    a.profit_flag,
    RANK() OVER (PARTITION BY a.s_store_name ORDER BY a.total_net_paid DESC) AS revenue_rank,
    sa.store_avg_profit
FROM agg a
LEFT JOIN store_avg sa ON a.s_store_sk = sa.s_store_sk
ORDER BY a.total_net_paid DESC
LIMIT 100
