WITH
sales_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_brand,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        AVG(c.c_birth_year) AS avg_birth_year,
        COUNT(*) AS sales_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND s.s_state IN ('CA', 'TX', 'NY')
    GROUP BY d.d_year, d.d_quarter_name, s.s_store_sk, s.s_store_name, s.s_state, i.i_category, i.i_brand
),
brand_rank AS (
    SELECT
        d_year,
        d_quarter_name,
        s_store_sk,
        s_store_name,
        s_state,
        i_category,
        i_brand,
        sales_amount,
        net_profit,
        distinct_customers,
        avg_birth_year,
        sales_count,
        RANK() OVER (PARTITION BY d_year, d_quarter_name, s_store_sk, i_category ORDER BY sales_amount DESC) AS brand_rnk
    FROM sales_agg
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        sr.sr_store_sk AS s_store_sk,
        SUM(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, d.d_quarter_name, sr.sr_store_sk
),
promo_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        ss.ss_store_sk AS s_store_sk,
        SUM(p.p_cost) AS promo_cost
    FROM store_sales ss
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, d.d_quarter_name, ss.ss_store_sk
)
SELECT
    br.d_year,
    br.d_quarter_name,
    br.s_store_name,
    br.s_state,
    br.i_category,
    br.i_brand,
    br.sales_amount,
    br.net_profit,
    COALESCE(r.return_loss, 0) AS return_loss,
    br.sales_amount - COALESCE(r.return_loss, 0) AS net_revenue,
    COALESCE(p.promo_cost, 0) AS promo_cost,
    br.distinct_customers,
    CAST(br.avg_birth_year AS INTEGER) AS avg_customer_birth_year,
    br.sales_count,
    br.brand_rnk
FROM brand_rank br
LEFT JOIN returns_agg r
    ON br.d_year = r.d_year
   AND br.d_quarter_name = r.d_quarter_name
   AND br.s_store_sk = r.s_store_sk
LEFT JOIN promo_agg p
    ON br.d_year = p.d_year
   AND br.d_quarter_name = p.d_quarter_name
   AND br.s_store_sk = p.s_store_sk
WHERE br.brand_rnk <= 3
ORDER BY br.d_year, br.d_quarter_name, br.s_store_name, br.i_category, br.brand_rnk
