WITH inventory_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    d_sales.d_year,
    w.w_warehouse_name,
    w.w_county,
    i1.i_category,
    r.r_reason_desc,
    SUM(ss.ss_net_paid) AS total_sales_amount,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(ss.ss_net_profit) - SUM(wr.wr_net_loss) AS net_profit,
    SUM(inv_agg.total_quantity_on_hand) AS total_inventory_qty
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i1
    ON ss.ss_item_sk = i1.i_item_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i1.i_item_sk
JOIN date_dim d_returns
    ON wr.wr_returned_date_sk = d_returns.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_page
    ON wp.wp_access_date_sk = d_page.d_date_sk
JOIN inventory_agg inv_agg
    ON inv_agg.inv_date_sk = d_sales.d_date_sk
JOIN warehouse w
    ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    w.w_county = 'Richland County'
    AND i1.i_brand_id = 12
    AND d_sales.d_year = 2001
    AND wp.wp_autogen_flag = 'N'
GROUP BY
    d_sales.d_year,
    w.w_warehouse_name,
    w.w_county,
    i1.i_category,
    r.r_reason_desc
HAVING
    SUM(ss.ss_net_paid) > 100000
    AND SUM(inv_agg.total_quantity_on_hand) > 5000
ORDER BY
    total_sales_amount DESC
LIMIT 100
