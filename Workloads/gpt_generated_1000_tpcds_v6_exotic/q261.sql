WITH sales_returns AS (
    SELECT
        p.p_promo_id AS promo_id,
        td.t_hour   AS hour,
        cd_bill.cd_gender AS gender,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit)      AS total_profit,
        SUM(wr.wr_return_amt)      AS total_returns,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        COUNT(wr.wr_return_quantity)       AS return_items
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd_refund
        ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND p.p_channel_dmail = 'Y'
      AND cd_bill.cd_dep_college_count >= 2
      AND cs.cs_ext_wholesale_cost > 1000
      AND cd_refund.cd_dep_employed_count >= 2
    GROUP BY p.p_promo_id, td.t_hour, cd_bill.cd_gender
)
SELECT
    promo_id,
    hour,
    gender,
    SUM(total_sales)   AS total_sales,
    SUM(total_profit)  AS total_profit,
    SUM(total_returns) AS total_returns,
    SUM(orders)        AS orders,
    SUM(return_items)  AS return_items,
    SUM(total_sales) - SUM(total_returns) AS net_sales
FROM sales_returns
GROUP BY GROUPING SETS (
    (promo_id, hour, gender),
    (promo_id, hour),
    (promo_id),
    ()
)
HAVING (SUM(total_sales) - SUM(total_returns)) > 5000
ORDER BY promo_id, hour, gender
LIMIT 100
