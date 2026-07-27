WITH ss AS (
        SELECT ss_item_sk,
               SUM(ss_net_profit) AS store_profit
        FROM store_sales
        WHERE ss_sold_date_sk BETWEEN 2450000 AND 2459999
        GROUP BY ss_item_sk
    ),
    ws AS (
        SELECT ws_item_sk,
               SUM(ws_net_profit) AS web_profit
        FROM web_sales
        WHERE ws_sold_date_sk BETWEEN 2450000 AND 2459999
        GROUP BY ws_item_sk
    ),
    cr AS (
        SELECT cr_item_sk,
               SUM(cr_return_amount) AS catalog_return_amount,
               MAX(cr_call_center_sk) AS cr_call_center_sk,
               MAX(cr_catalog_page_sk) AS cr_catalog_page_sk,
               MAX(cr_reason_sk) AS cr_reason_sk
        FROM catalog_returns
        GROUP BY cr_item_sk
    ),
    wr AS (
        SELECT wr_item_sk,
               SUM(wr_return_amt) AS web_return_amount
        FROM web_returns
        GROUP BY wr_item_sk
    ),
    inv AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory
        GROUP BY inv_item_sk
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    COALESCE(ss.store_profit, 0) AS store_profit,
    COALESCE(ws.web_profit, 0) AS web_profit,
    COALESCE(cr.catalog_return_amount, 0) AS catalog_return_amount,
    COALESCE(wr.web_return_amount, 0) AS web_return_amount,
    (COALESCE(ss.store_profit, 0) + COALESCE(ws.web_profit, 0) - COALESCE(cr.catalog_return_amount, 0) - COALESCE(wr.web_return_amount, 0)) AS net_profit,
    inv.total_on_hand,
    cc.cc_company_name,
    cp.cp_description AS catalog_page_desc,
    r.r_reason_desc,
    RANK() OVER (ORDER BY (COALESCE(ss.store_profit, 0) + COALESCE(ws.web_profit, 0) - COALESCE(cr.catalog_return_amount, 0) - COALESCE(wr.web_return_amount, 0)) DESC) AS profit_rank
FROM item i
JOIN promotion p ON p.p_item_sk = i.i_item_sk
LEFT JOIN ss ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN wr ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN inv ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN call_center cc ON cc.cc_call_center_sk = cr.cr_call_center_sk
LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
LEFT JOIN reason r ON r.r_reason_sk = cr.cr_reason_sk
WHERE p.p_discount_active = 'Y'
  AND cc.cc_state = 'CA'
  AND inv.total_on_hand > 0
ORDER BY net_profit DESC
LIMIT 100
