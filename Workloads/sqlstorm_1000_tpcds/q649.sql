WITH
sales AS (
    SELECT
        d.d_year,
        d.d_qoy AS d_quarter,
        s.s_state AS state,
        'store' AS channel,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_customer_sk AS customer_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_qoy AS d_quarter,
        cc.cc_state,
        'catalog',
        i.i_category,
        i.i_class,
        i.i_brand,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_qoy AS d_quarter,
        w.web_state,
        'web',
        i.i_category,
        i.i_class,
        i.i_brand,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
sales_agg AS (
    SELECT
        d_year,
        d_quarter,
        state,
        channel,
        category,
        class,
        brand,
        SUM(quantity) AS total_qty,
        SUM(sales_amount) AS total_sales,
        SUM(net_profit) AS total_net_profit,
        SUM(discount_amt) AS total_discount,
        COUNT(DISTINCT customer_sk) AS distinct_customers,
        approx_percentile(CAST(discount_amt AS double) / NULLIF(sales_amount, 0), 0.5) AS median_discount_rate
    FROM sales
    GROUP BY d_year, d_quarter, state, channel, category, class, brand
),
returns AS (
    SELECT
        d.d_year,
        d.d_qoy AS d_quarter,
        s.s_state AS state,
        'store' AS channel,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        sr.sr_return_quantity AS qty,
        sr.sr_net_loss AS net_loss,
        sr.sr_fee AS fee,
        sr.sr_refunded_cash AS refunded_cash
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_qoy AS d_quarter,
        cc.cc_state,
        'catalog',
        i.i_category,
        i.i_class,
        i.i_brand,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_fee,
        cr.cr_refunded_cash
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
),
returns_agg AS (
    SELECT
        d_year,
        d_quarter,
        state,
        channel,
        category,
        class,
        brand,
        SUM(qty) AS total_return_qty,
        SUM(net_loss) AS total_return_loss,
        SUM(fee) AS total_return_fee,
        SUM(refunded_cash) AS total_refunded_cash
    FROM returns
    GROUP BY d_year, d_quarter, state, channel, category, class, brand
),
joined AS (
    SELECT
        s.d_year,
        s.d_quarter,
        s.state,
        s.channel,
        s.category,
        s.class,
        s.brand,
        s.total_qty,
        s.total_sales,
        s.total_net_profit,
        s.total_discount,
        s.distinct_customers,
        s.median_discount_rate,
        COALESCE(r.total_return_qty, 0) AS total_return_qty,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        COALESCE(r.total_return_fee, 0) AS total_return_fee,
        COALESCE(r.total_refunded_cash, 0) AS total_refunded_cash,
        s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_adj
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_year = r.d_year
       AND s.d_quarter = r.d_quarter
       AND s.state = r.state
       AND s.channel = r.channel
       AND s.category = r.category
       AND s.class = r.class
       AND s.brand = r.brand
),
brand_rank AS (
    SELECT
        d_year,
        d_quarter,
        state,
        channel,
        brand,
        SUM(total_net_profit) AS brand_net_profit,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_quarter, state, channel ORDER BY SUM(total_net_profit) DESC) AS rn
    FROM joined
    GROUP BY d_year, d_quarter, state, channel, brand
),
top_brand AS (
    SELECT d_year, d_quarter, state, channel, brand AS top_brand
    FROM brand_rank
    WHERE rn = 1
)
SELECT
    j.d_year,
    j.d_quarter,
    j.state,
    j.channel,
    j.category,
    j.class,
    j.brand,
    j.total_qty,
    j.total_sales,
    j.total_net_profit,
    j.total_discount,
    j.distinct_customers,
    j.median_discount_rate,
    j.total_return_qty,
    j.total_return_loss,
    j.total_refunded_cash,
    j.net_profit_adj,
    CASE WHEN j.total_sales = 0 THEN 0 ELSE j.total_discount / j.total_sales END AS discount_rate,
    LAG(j.net_profit_adj) OVER (PARTITION BY j.state, j.channel, j.category, j.class, j.brand ORDER BY j.d_year, j.d_quarter) AS prev_qtr_adj_profit,
    (j.net_profit_adj - LAG(j.net_profit_adj) OVER (PARTITION BY j.state, j.channel, j.category, j.class, j.brand ORDER BY j.d_year, j.d_quarter))
        / NULLIF(LAG(j.net_profit_adj) OVER (PARTITION BY j.state, j.channel, j.category, j.class, j.brand ORDER BY j.d_year, j.d_quarter), 0) AS qoq_adj_profit_growth,
    tb.top_brand
FROM joined j
LEFT JOIN top_brand tb
    ON j.d_year = tb.d_year
   AND j.d_quarter = tb.d_quarter
   AND j.state = tb.state
   AND j.channel = tb.channel
WHERE j.d_year IN (2001, 2002) AND j.state IS NOT NULL
ORDER BY j.d_year, j.d_quarter, j.state, j.channel, j.total_net_profit DESC
LIMIT 1000
