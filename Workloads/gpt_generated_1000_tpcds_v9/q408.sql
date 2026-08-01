SELECT
    item_id,
    metric_type,
    total_amount,
    total_quantity
FROM (
    SELECT
        i.i_item_id AS item_id,
        'sales' AS metric_type,
        SUM(cs.cs_net_paid_inc_tax) AS total_amount,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2021
      AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
    GROUP BY i.i_item_id
    HAVING SUM(cs.cs_net_paid_inc_tax) > 10000

    UNION ALL

    SELECT
        i.i_item_id AS item_id,
        'returns' AS metric_type,
        SUM(wr.wr_return_amt_inc_tax) AS total_amount,
        SUM(wr.wr_return_quantity) AS total_quantity
    FROM web_returns wr
    INNER JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    INNER JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2021
      AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
    GROUP BY i.i_item_id
    HAVING SUM(wr.wr_return_amt_inc_tax) > 5000
) AS combined
ORDER BY total_amount DESC
LIMIT 100
