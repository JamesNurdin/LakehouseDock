WITH base_data AS (
    SELECT
        d.d_year,
        s.s_store_sk,
        s.s_store_name,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_item_sk,
        c.c_customer_sk,
        ca.ca_state,
        cd.cd_demo_sk,
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        inv.inv_quantity_on_hand,
        ws.ws_quantity,
        ws.ws_net_paid,
        cc.cc_call_center_sk,
        cc.cc_state,
        p.p_promo_sk,
        p.p_discount_active,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        wp.wp_url
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 1998
      AND cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand > 0
      AND EXISTS (
          SELECT 1
          FROM reason r
          WHERE r.r_reason_sk = sr.sr_reason_sk
            AND r.r_reason_desc = 'Damaged'
      )
)
SELECT
    agg.d_year,
    agg.s_store_sk,
    agg.s_store_name,
    SUM(agg.cs_net_profit) AS total_net_profit,
    SUM(agg.cs_quantity) AS total_quantity_sold,
    CASE WHEN SUM(agg.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
    (
        SELECT COUNT(DISTINCT ws2.ws_bill_customer_sk)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = agg.d_year
    ) AS distinct_web_customers,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY SUM(agg.cs_net_profit) DESC) AS profit_rank
FROM base_data agg
GROUP BY agg.d_year, agg.s_store_sk, agg.s_store_name
HAVING SUM(agg.cs_net_profit) > 1000
ORDER BY agg.d_year DESC, profit_rank
LIMIT 100
