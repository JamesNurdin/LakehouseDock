/*
Goal: Identify the top‑selling items for the year 2001 across catalog, web, and store channels, classify their profitability, and exclude any items that also had a store return on the same sale date. The query joins all fourteen selected TPC‑DS tables using only the permitted surrogate‑key relationships, applies multiple filter predicates, uses a CASE expression, a correlated scalar subquery, window‑function rankings, and an anti‑join.
*/
WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        d_sales.d_year,
        p.p_promo_id,
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        inv.inv_quantity_on_hand,
        store.s_state,
        r.r_reason_desc,
        customer.c_customer_id,
        cd.cd_gender
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
           AND ws.ws_sold_date_sk = d_sales.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
           AND inv.inv_date_sk = d_sales.d_date_sk
    LEFT JOIN store
        ON sr.sr_store_sk = store.s_store_sk
    LEFT JOIN date_dim d_store_return
        ON sr.sr_returned_date_sk = d_store_return.d_date_sk
    LEFT JOIN customer
        ON cs.cs_bill_customer_sk = customer.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d_sales.d_year = 2001                              -- predicate 1
      AND i.i_current_price > 50                              -- predicate 2
      AND store.s_state = 'CA'                                -- predicate 3
      AND p.p_discount_active = 'Y'                           -- predicate 4
      AND cc.cc_gmt_offset BETWEEN -5 AND 2                  -- predicate 5
)
SELECT
    i_item_id,
    i_category,
    d_year,
    SUM(cs_net_profit) AS total_sales_profit,
    SUM(COALESCE(ws_net_profit, 0)) AS total_web_profit,
    SUM(COALESCE(sr_net_loss, 0)) AS total_store_return_loss,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE cs2.cs_item_sk = sales_data.cs_item_sk
          AND d2.d_year = 2001
    ) AS avg_item_profit,
    CASE
        WHEN SUM(cs_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(cs_net_profit) > 50000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_level,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(cs_net_profit) DESC) AS rank_within_category,
    DENSE_RANK() OVER (ORDER BY SUM(cs_net_profit) DESC) AS overall_rank
FROM sales_data
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_item_sk = sales_data.cs_item_sk
      AND sr2.sr_returned_date_sk = sales_data.cs_sold_date_sk
)
GROUP BY i_item_id, i_category, d_year, cs_item_sk
HAVING SUM(cs_net_profit) > 0
ORDER BY overall_rank
LIMIT 100
