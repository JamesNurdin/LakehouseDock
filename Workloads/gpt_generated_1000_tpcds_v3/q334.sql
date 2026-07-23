WITH item_sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_sk AS item_sk,
        sd.d_date AS sold_date,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_returns,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN date_dim sd
        ON cs.cs_sold_date_sk = sd.d_date_sk
    JOIN time_dim st
        ON cs.cs_sold_time_sk = st.t_time_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = sd.d_date_sk
        AND wr.wr_returned_time_sk = st.t_time_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = sd.d_date_sk
    WHERE
        sd.d_year = 1998
        AND i.i_category = 'Sports'
        AND c_bill.c_birth_country = 'SWITZERLAND'
        AND inv.inv_quantity_on_hand > 200
        AND cs.cs_quantity > 1
    GROUP BY
        i.i_item_id,
        i.i_item_sk,
        sd.d_date
)
SELECT
    agg.item_id,
    SUM(agg.total_sales) AS sum_sales,
    SUM(agg.total_returns) AS sum_returns,
    SUM(agg.total_sales - agg.total_returns) AS net_sales,
    CASE
        WHEN SUM(agg.total_sales - agg.total_returns) > (SELECT AVG(total_sales) FROM item_sales_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category,
    (SELECT COUNT(DISTINCT wr2.wr_returning_customer_sk)
     FROM web_returns wr2
     WHERE wr2.wr_item_sk = agg.item_sk) AS distinct_return_customers
FROM item_sales_agg agg
GROUP BY agg.item_id, agg.item_sk
HAVING SUM(agg.total_sales - agg.total_returns) > 0
ORDER BY net_sales DESC
LIMIT 100
