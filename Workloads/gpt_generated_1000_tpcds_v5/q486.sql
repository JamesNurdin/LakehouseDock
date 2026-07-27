WITH sales_agg AS (
    SELECT
        d.d_date,
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        COALESCE(inv.inv_quantity_on_hand, 0) AS inventory_on_hand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT OUTER JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand_id = 5
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND inv.inv_quantity_on_hand > 100
    GROUP BY d.d_date, i.i_item_sk, i.i_item_id, i.i_category, inv.inv_quantity_on_hand
)
SELECT
    sa.d_date,
    sa.i_category,
    SUM(sa.total_sales) AS day_total_sales,
    AVG(sa.total_profit) AS avg_profit_per_item,
    SUM(sa.sales_cnt) AS total_transactions,
    COUNT(DISTINCT wr.wr_return_quantity) AS distinct_return_qty
FROM sales_agg sa
JOIN date_dim d2 ON d2.d_date = sa.d_date
JOIN item i2 ON i2.i_item_sk = sa.i_item_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d2.d_date_sk
                     AND wr.wr_item_sk = i2.i_item_sk
GROUP BY sa.d_date, sa.i_category
HAVING SUM(sa.total_sales) > 10000
ORDER BY day_total_sales DESC
LIMIT 100
