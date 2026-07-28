WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        s.s_store_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND cd.cd_gender = 'M'
      AND w.w_state = 'CA'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_category, s.s_store_name
),
category_stats AS (
    SELECT
        i_category,
        SUM(total_net_profit) AS cat_total_profit,
        AVG(total_net_profit) AS cat_avg_profit,
        SUM(total_quantity) AS cat_total_qty
    FROM sales_agg
    GROUP BY i_category
    HAVING SUM(total_quantity) > 500
)
SELECT
    sa.i_item_id,
    sa.i_category,
    sa.s_store_name,
    sa.total_net_profit,
    sa.total_quantity,
    sa.avg_sales_price,
    cs.cat_total_profit,
    RANK() OVER (ORDER BY sa.total_net_profit DESC) AS profit_rank,
    SUM(sa.total_net_profit) OVER (PARTITION BY sa.i_category) AS running_category_profit
FROM sales_agg sa
JOIN category_stats cs
    ON sa.i_category = cs.i_category
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = sa.i_item_sk
)
ORDER BY sa.total_net_profit DESC
LIMIT 100
