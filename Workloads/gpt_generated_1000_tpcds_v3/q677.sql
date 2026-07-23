WITH sales_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_time_sk,
        ss_addr_sk,
        ss_cdemo_sk,
        ss_promo_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_item_sk, ss_sold_time_sk, ss_addr_sk, ss_cdemo_sk, ss_promo_sk
),
returns_agg AS (
    SELECT
        wr_item_sk,
        wr_returned_time_sk,
        wr_refunded_addr_sk,
        wr_refunded_cdemo_sk,
        SUM(wr_return_quantity) AS total_return_qty,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_return_loss
    FROM web_returns
    WHERE wr_return_quantity > 0
    GROUP BY wr_item_sk, wr_returned_time_sk, wr_refunded_addr_sk, wr_refunded_cdemo_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    ca_sales.ca_state,
    cd_sales.cd_gender,
    cd_sales.cd_credit_rating,
    td_sales.t_hour AS sale_hour,
    td_ret.t_hour AS return_hour,
    sa.total_quantity,
    sa.total_sales,
    sa.total_net_profit,
    ra.total_return_qty,
    ra.total_return_amt,
    CASE
        WHEN sa.total_net_profit > 10000 THEN 'High Profit'
        WHEN sa.total_net_profit > 0 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    RANK() OVER (PARTITION BY i.i_category ORDER BY sa.total_net_profit DESC) AS profit_rank_in_category,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY sa.total_net_profit DESC) AS row_num_in_category,
    SUM(sa.total_net_profit) OVER (PARTITION BY i.i_item_id ORDER BY td_sales.t_hour ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS net_profit_3h_moving_sum
FROM sales_agg sa
JOIN item i
    ON i.i_item_sk = sa.ss_item_sk
JOIN promotion p
    ON p.p_promo_sk = sa.ss_promo_sk
    AND p.p_item_sk = i.i_item_sk
JOIN time_dim td_sales
    ON td_sales.t_time_sk = sa.ss_sold_time_sk
JOIN customer_address ca_sales
    ON ca_sales.ca_address_sk = sa.ss_addr_sk
JOIN customer_demographics cd_sales
    ON cd_sales.cd_demo_sk = sa.ss_cdemo_sk
LEFT JOIN returns_agg ra
    ON ra.wr_item_sk = i.i_item_sk
LEFT JOIN time_dim td_ret
    ON td_ret.t_time_sk = ra.wr_returned_time_sk
LEFT JOIN customer_address ca_returns
    ON ca_returns.ca_address_sk = ra.wr_refunded_addr_sk
LEFT JOIN customer_demographics cd_returns
    ON cd_returns.cd_demo_sk = ra.wr_refunded_cdemo_sk
WHERE i.i_category = 'Electronics'
  AND i.i_brand = 'BrandX'
  AND p.p_discount_active = 'Y'
  AND ca_sales.ca_state = 'CA'
  AND cd_sales.cd_credit_rating = 'Good'
  AND cd_sales.cd_education_status = 'College'
  AND td_sales.t_hour BETWEEN 9 AND 17
ORDER BY i.i_category, profit_rank_in_category, i.i_item_id
LIMIT 100
