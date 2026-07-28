WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
),
base AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        d_cs.d_date,
        cs.cs_net_profit            AS catalog_profit,
        ss.ss_net_profit            AS store_profit,
        ws.ws_net_profit            AS web_profit,
        sr.sr_net_loss              AS store_loss,
        wr.wr_net_loss              AS web_loss,
        inv_agg.total_on_hand
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_date_sk = d_cs.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d_cs.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
        AND inv_agg.inv_date_sk = d_cs.d_date_sk
    WHERE d_cs.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-01-31'
      AND i.i_color = 'Red'
      AND p.p_discount_active = 'Y'
      AND r_sr.r_reason_id = 'AAAAAAAABBAAAAAA'
      AND inv_agg.total_on_hand > 1000
),
agg AS (
    SELECT
        b.c_customer_id,
        b.i_item_id,
        b.d_date,
        SUM(COALESCE(b.catalog_profit,0) + COALESCE(b.store_profit,0) + COALESCE(b.web_profit,0)
            - COALESCE(b.store_loss,0) - COALESCE(b.web_loss,0)) AS net_total_profit,
        COUNT(DISTINCT b.c_customer_id) AS distinct_customers,
        CASE WHEN SUM(COALESCE(b.store_loss,0)) > 0 THEN 'Store Return' ELSE 'No Store Return' END AS store_return_flag
    FROM base b
    GROUP BY b.c_customer_id, b.i_item_id, b.d_date
    HAVING SUM(COALESCE(b.catalog_profit,0) + COALESCE(b.store_profit,0) + COALESCE(b.web_profit,0)
               - COALESCE(b.store_loss,0) - COALESCE(b.web_loss,0)) > 0
)
SELECT
    a.c_customer_id,
    a.i_item_id,
    a.d_date,
    a.net_total_profit,
    ROW_NUMBER() OVER (PARTITION BY a.c_customer_id ORDER BY a.net_total_profit DESC) AS profit_rank,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_catalog_profit,
    a.distinct_customers,
    a.store_return_flag
FROM agg a
ORDER BY a.net_total_profit DESC
LIMIT 100
