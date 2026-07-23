WITH avg_item_return AS (
    SELECT cr2.cr_item_sk,
           AVG(cr2.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr2
    GROUP BY cr2.cr_item_sk
),
ws_sales_agg AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(*) AS sales_cnt
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_catalog_number,
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    cr.cr_return_amount,
    cr.cr_net_loss,
    CASE
        WHEN cr.cr_return_amount > avg_item_return.avg_return_amount THEN 'Above Avg Return'
        ELSE 'Below Avg Return'
    END AS return_vs_item_avg,
    p.p_promo_name,
    p.p_channel_catalog,
    ws_sales_agg.total_sales,
    ws_sales_agg.total_profit,
    (SELECT AVG(cr3.cr_return_amount) FROM catalog_returns cr3) AS overall_avg_return_amount,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY cr.cr_net_loss DESC) AS dept_net_loss_rank,
    ROW_NUMBER() OVER (ORDER BY cr.cr_return_amount DESC) AS overall_return_amount_rn
FROM catalog_returns cr
INNER JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
INNER JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
INNER JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
INNER JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
INNER JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
    AND p.p_item_sk = i.i_item_sk
INNER JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
INNER JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
INNER JOIN avg_item_return
    ON cr.cr_item_sk = avg_item_return.cr_item_sk
INNER JOIN ws_sales_agg
    ON i.i_item_sk = ws_sales_agg.ws_item_sk
WHERE cp.cp_catalog_number IN (1, 8, 15)
  AND i.i_current_price BETWEEN 20 AND 100
  AND hd_refunded.hd_buy_potential = '1001-5000'
  AND p.p_channel_catalog = 'N'
  AND ws.ws_quantity > 5
LIMIT 100
