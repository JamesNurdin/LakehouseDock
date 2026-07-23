WITH returns_summary AS (
    SELECT
        i.i_item_sk,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS store_return_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        SUM(wr.wr_net_loss) AS web_return_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_tax < 5.00
      AND sr.sr_reversed_charge > 10.00
      AND (wr.wr_return_tax < 5.00 OR wr.wr_return_tax IS NULL)
      AND (wr.wr_reversed_charge > 10.00 OR wr.wr_reversed_charge IS NULL)
    GROUP BY i.i_item_sk, r.r_reason_desc
),

sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        c.c_customer_id,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_tax) AS total_ext_tax,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transaction_cnt
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_ext_tax > 10.00
      AND ss.ss_list_price BETWEEN 50 AND 150
      AND c.c_birth_year = 1985
      AND i.i_brand = 'Brand#34'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        c.c_customer_id,
        t.t_hour
    HAVING SUM(ss.ss_ext_sales_price) > 1000
)

SELECT
    sa.i_item_id,
    sa.i_product_name,
    sa.i_brand,
    sa.i_category,
    sa.c_customer_id,
    sa.t_hour,
    sa.total_sales,
    sa.total_net_profit,
    COALESCE(rs.store_return_loss, 0) AS store_return_loss,
    COALESCE(rs.web_return_loss, 0) AS web_return_loss,
    CASE
        WHEN sa.total_net_profit - COALESCE(rs.store_return_loss, 0) - COALESCE(rs.web_return_loss, 0) > 0
        THEN 'PROFIT'
        ELSE 'LOSS'
    END AS overall_profit_flag,
    ROW_NUMBER() OVER (PARTITION BY sa.i_brand ORDER BY sa.total_net_profit DESC) AS brand_item_rank
FROM sales_agg sa
LEFT JOIN returns_summary rs
    ON sa.i_item_sk = rs.i_item_sk
WHERE (COALESCE(rs.store_return_loss, 0) + COALESCE(rs.web_return_loss, 0)) > 200
ORDER BY sa.total_net_profit DESC
LIMIT 100
