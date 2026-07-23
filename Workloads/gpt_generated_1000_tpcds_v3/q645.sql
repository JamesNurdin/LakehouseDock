WITH distinct_items AS (
    SELECT DISTINCT inv_item_sk
    FROM inventory
),
agg_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_store_sk,
        ss_item_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_store_sk, ss_item_sk
),
agg_inventory AS (
    SELECT
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        AVG(inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
),
agg_returns AS (
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        wr_reason_sk,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM web_returns
    GROUP BY wr_returned_date_sk, wr_item_sk, wr_reason_sk
)
SELECT
    s.s_store_name,
    i_sales.i_product_name,
    i_return.i_product_name AS return_product_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    reason.r_reason_desc,
    SUM(a_sales.total_net_paid) AS total_sales,
    SUM(a_sales.total_net_profit) AS total_profit,
    SUM(a_inv.total_quantity_on_hand) AS total_inventory_on_hand,
    SUM(a_returns.total_return_loss) AS total_return_loss,
    COUNT(DISTINCT a_sales.ss_sold_date_sk) AS distinct_sales_dates
FROM agg_sales a_sales
JOIN date_dim d_sales
    ON a_sales.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON a_sales.ss_store_sk = s.s_store_sk
JOIN item i_sales
    ON a_sales.ss_item_sk = i_sales.i_item_sk
JOIN agg_inventory a_inv
    ON a_sales.ss_sold_date_sk = a_inv.inv_date_sk
   AND a_sales.ss_item_sk = a_inv.inv_item_sk
JOIN date_dim d_inventory
    ON a_inv.inv_date_sk = d_inventory.d_date_sk
JOIN item i_inventory
    ON a_inv.inv_item_sk = i_inventory.i_item_sk
JOIN agg_returns a_returns
    ON a_sales.ss_sold_date_sk = a_returns.wr_returned_date_sk
   AND a_sales.ss_item_sk = a_returns.wr_item_sk
JOIN date_dim d_return
    ON a_returns.wr_returned_date_sk = d_return.d_date_sk
JOIN item i_return
    ON a_returns.wr_item_sk = i_return.i_item_sk
JOIN reason
    ON a_returns.wr_reason_sk = reason.r_reason_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN distinct_items di
    ON di.inv_item_sk = i_sales.i_item_sk
WHERE d_sales.d_year = 2000
GROUP BY
    s.s_store_name,
    i_sales.i_product_name,
    i_return.i_product_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    reason.r_reason_desc
ORDER BY total_sales DESC
LIMIT 100
