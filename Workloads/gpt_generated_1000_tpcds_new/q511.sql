WITH base AS (
   SELECT
       cp.cp_catalog_page_id,
       cp.cp_catalog_number,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       hd.hd_demo_sk,
       hd.hd_dep_count,
       hd.hd_buy_potential,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       s.s_store_id,
       s.s_state,
       s.s_suite_number,
       ws.ws_order_number,
       ws.ws_quantity,
       ws.ws_net_profit,
       ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ws.ws_net_profit DESC) AS profit_rank,
       CASE WHEN ws.ws_net_profit > 1000 THEN 'High' WHEN ws.ws_net_profit > 0 THEN 'Medium' ELSE 'Low' END AS profit_category
   FROM catalog_page cp
   JOIN catalog_returns cr
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN household_demographics hd
     ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN store_returns sr
     ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   JOIN web_sales ws
     ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   WHERE cp.cp_catalog_number IN (6,12,13)
     AND cp.cp_catalog_page_id LIKE 'AAAA%'
     AND cr.cr_return_quantity > 1
     AND hd.hd_dep_count BETWEEN 1 AND 3
     AND hd.hd_buy_potential = '5001-10000'
     AND s.s_state = 'CA'
     AND ws.ws_quantity >= 2
     AND s.s_suite_number = 'Suite 180'
)
SELECT
    cp_catalog_page_id,
    cp_catalog_number,
    cr_return_quantity,
    cr_return_amount,
    hd_demo_sk,
    hd_dep_count,
    hd_buy_potential,
    sr_return_quantity,
    sr_return_amt,
    s_store_id,
    s_state,
    s_suite_number,
    ws_order_number,
    ws_quantity,
    ws_net_profit,
    profit_rank,
    profit_category
FROM base
WHERE profit_rank <= 5

UNION

SELECT
    cp_catalog_page_id,
    cp_catalog_number,
    cr_return_quantity,
    cr_return_amount,
    hd_demo_sk,
    hd_dep_count,
    hd_buy_potential,
    sr_return_quantity,
    sr_return_amt,
    s_store_id,
    s_state,
    s_suite_number,
    ws_order_number,
    ws_quantity,
    ws_net_profit,
    profit_rank,
    profit_category
FROM (
   SELECT
       cp.cp_catalog_page_id,
       cp.cp_catalog_number,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       hd.hd_demo_sk,
       hd.hd_dep_count,
       hd.hd_buy_potential,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       s.s_store_id,
       s.s_state,
       s.s_suite_number,
       ws.ws_order_number,
       ws.ws_quantity,
       ws.ws_net_profit,
       ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ws.ws_net_profit DESC) AS profit_rank,
       CASE WHEN ws.ws_net_profit > 1000 THEN 'High' WHEN ws.ws_net_profit > 0 THEN 'Medium' ELSE 'Low' END AS profit_category
   FROM catalog_page cp
   JOIN catalog_returns cr
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN household_demographics hd
     ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   JOIN store_returns sr
     ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   JOIN web_sales ws
     ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
   WHERE cp.cp_catalog_number IN (6,12,13)
     AND cp.cp_catalog_page_id LIKE 'AAAA%'
     AND cr.cr_return_quantity > 1
     AND hd.hd_dep_count BETWEEN 1 AND 3
     AND hd.hd_buy_potential = '5001-10000'
     AND s.s_state = 'CA'
     AND ws.ws_quantity >= 2
     AND s.s_suite_number = 'Suite 180'
) sub
CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2) dim
WHERE profit_rank <= 5
ORDER BY s_store_id, profit_rank
LIMIT 100
