WITH agg_sales AS (
    SELECT
        s.s_store_id,
        i.i_item_id,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ss.ss_net_profit + cs.cs_net_profit + ws.ws_net_profit) AS total_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE s.s_number_employees > 200
      AND i.i_current_price > 20
      AND cs.cs_ship_mode_sk IS NOT NULL
    GROUP BY s.s_store_id, i.i_item_id
)
SELECT
    a.s_store_id,
    a.i_item_id,
    a.total_profit,
    AVG(a.total_profit) OVER (PARTITION BY a.s_store_id) AS avg_profit_per_store,
    RANK() OVER (ORDER BY a.total_profit DESC) AS profit_rank,
    ls.item_store_sales,
    cr.cr_return_amount,
    r.r_reason_desc,
    sm.sm_type,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_buy_potential,
    wp.wp_url
FROM agg_sales a
JOIN item i ON i.i_item_id = a.i_item_id
JOIN store s ON s.s_store_id = a.s_store_id
JOIN catalog_sales cs2 ON cs2.cs_item_sk = i.i_item_sk
JOIN catalog_returns cr ON cr.cr_item_sk = cs2.cs_item_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
JOIN customer_address ca ON ca.ca_address_sk = cs2.cs_bill_addr_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = cs2.cs_bill_cdemo_sk
JOIN household_demographics hd ON hd.hd_demo_sk = cs2.cs_bill_hdemo_sk
JOIN web_sales ws3 ON ws3.ws_item_sk = i.i_item_sk
JOIN web_page wp ON ws3.ws_web_page_sk = wp.wp_web_page_sk
CROSS JOIN LATERAL (
    SELECT SUM(ss_inner.ss_ext_sales_price) AS item_store_sales
    FROM store_sales ss_inner
    WHERE ss_inner.ss_item_sk = i.i_item_sk
) ls
WHERE r.r_reason_desc LIKE '%gift%'
  AND cr.cr_return_amount > 0
  AND sm.sm_type = 'AIR'
  AND a.total_profit > 1000
ORDER BY a.total_profit DESC
LIMIT 100
