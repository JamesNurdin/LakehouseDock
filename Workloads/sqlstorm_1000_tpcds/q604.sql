WITH sales_agg AS (
    SELECT
        d.d_year,
        s.s_store_name,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_channel_email = 'Y'
    GROUP BY d.d_year, s.s_store_name, i.i_category
),
returns_agg AS (
    SELECT
        d.d_year,
        s.s_store_name,
        i.i_category,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, s.s_store_name, i.i_category
)
SELECT
    COALESCE(sales.d_year, ret.d_year) AS year,
    COALESCE(sales.s_store_name, ret.s_store_name) AS store_name,
    COALESCE(sales.i_category, ret.i_category) AS category,
    COALESCE(sales.total_quantity, 0) - COALESCE(ret.total_return_quantity, 0) AS net_quantity,
    COALESCE(sales.total_sales, 0) - COALESCE(ret.total_return_amount, 0) AS net_sales,
    COALESCE(sales.total_net_profit, 0) - COALESCE(ret.total_return_net_loss, 0) AS net_profit_after_returns,
    COALESCE(sales.total_discount_amount, 0) AS total_discount_amount,
    COALESCE(ret.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(ret.total_return_amount, 0) AS total_return_amount
FROM sales_agg sales
FULL OUTER JOIN returns_agg ret
    ON sales.d_year = ret.d_year
   AND sales.s_store_name = ret.s_store_name
   AND sales.i_category = ret.i_category
ORDER BY net_profit_after_returns DESC
LIMIT 100
