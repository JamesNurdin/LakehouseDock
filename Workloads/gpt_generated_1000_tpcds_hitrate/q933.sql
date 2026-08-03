WITH base AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_quantity,
        i.i_current_price,
        i.i_manufact,
        w.w_city,
        p.p_discount_active,
        ib.ib_upper_bound,
        ca.ca_address_sk,
        sr.sr_return_quantity,
        ws.ws_quantity AS ws_quantity,
        web.web_name,
        t.t_time,
        LAG(cs.cs_net_paid) OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk) AS prev_net_paid
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    WHERE i.i_manufact = 'callyeingeing'
      AND w.w_city = 'Riverside'
      AND ib.ib_upper_bound <= 100000
      AND p.p_discount_active = 'Y'
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_item_sk = cs.cs_item_sk
            AND sr2.sr_returned_date_sk = cs.cs_sold_date_sk
      )
),
agg1 AS (
    SELECT
        cs_item_sk,
        SUM(cs_net_paid) AS total_net_paid,
        COUNT(*) AS num_sales,
        AVG(prev_net_paid) AS avg_prev_net_paid
    FROM base
    GROUP BY cs_item_sk
)
SELECT
    a.cs_item_sk,
    a.total_net_paid,
    a.num_sales,
    a.avg_prev_net_paid,
    (SELECT AVG(i_current_price) FROM item i2 WHERE i2.i_category = 'Electronics') AS avg_electronics_price,
    v.flag
FROM agg1 a
CROSS JOIN (VALUES 'A', 'B') AS v(flag)
WHERE a.total_net_paid > 1000
ORDER BY a.total_net_paid DESC
LIMIT 100
