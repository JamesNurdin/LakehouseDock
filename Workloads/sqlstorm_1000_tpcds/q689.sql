WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'store' AS channel,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_paid) AS sales_amount,
        SUM(ss.ss_ext_discount_amt) AS discount_amount,
        SUM(ss.ss_net_profit) AS profit_amount,
        SUM(ss.ss_quantity) AS quantity,
        SUM(ss.ss_ext_tax) AS tax_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, ss.ss_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        'catalog' AS channel,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_paid) AS sales_amount,
        SUM(cs.cs_ext_discount_amt) AS discount_amount,
        SUM(cs.cs_net_profit) AS profit_amount,
        SUM(cs.cs_quantity) AS quantity,
        SUM(cs.cs_ext_tax) AS tax_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, cs.cs_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        'web' AS channel,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_paid) AS sales_amount,
        SUM(ws.ws_ext_discount_amt) AS discount_amount,
        SUM(ws.ws_net_profit) AS profit_amount,
        SUM(ws.ws_quantity) AS quantity,
        SUM(ws.ws_ext_tax) AS tax_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, ws.ws_item_sk
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'store' AS channel,
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_return_amt_inc_tax) AS return_amount,
        SUM(sr.sr_fee) AS return_fee,
        SUM(sr.sr_net_loss) AS net_loss,
        SUM(sr.sr_return_quantity) AS return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, sr.sr_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        'catalog' AS channel,
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_return_amt_inc_tax) AS return_amount,
        SUM(cr.cr_fee) AS return_fee,
        SUM(cr.cr_net_loss) AS net_loss,
        SUM(cr.cr_return_quantity) AS return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, cr.cr_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        'web' AS channel,
        wr.wr_item_sk AS item_sk,
        SUM(wr.wr_return_amt_inc_tax) AS return_amount,
        SUM(wr.wr_fee) AS return_fee,
        SUM(wr.wr_net_loss) AS net_loss,
        SUM(wr.wr_return_quantity) AS return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, wr.wr_item_sk
),
promo_agg AS (
    SELECT
        p.p_item_sk AS item_sk,
        d.d_year,
        SUM(p.p_cost) AS promo_cost,
        COUNT(*) AS promo_count
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    GROUP BY p.p_item_sk, d.d_year
),
sales_returns_join AS (
    SELECT
        sa.d_year,
        sa.d_month_seq,
        sa.channel,
        sa.item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_class,
        i.i_manufact,
        sa.sales_amount,
        COALESCE(ra.return_amount, 0) AS return_amount,
        (sa.sales_amount - COALESCE(ra.return_amount, 0)) AS net_sales,
        sa.profit_amount,
        sa.discount_amount,
        sa.quantity,
        COALESCE(ra.return_quantity, 0) AS return_quantity,
        (sa.quantity - COALESCE(ra.return_quantity, 0)) AS net_quantity,
        COALESCE(pa.promo_cost, 0) AS promo_cost,
        COALESCE(pa.promo_count, 0) AS promo_count
    FROM sales_agg sa
    LEFT JOIN returns_agg ra ON ra.d_year = sa.d_year
        AND ra.d_month_seq = sa.d_month_seq
        AND ra.channel = sa.channel
        AND ra.item_sk = sa.item_sk
    LEFT JOIN promo_agg pa ON pa.item_sk = sa.item_sk
        AND pa.d_year = sa.d_year
    LEFT JOIN item i ON i.i_item_sk = sa.item_sk
),
ranked_items AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY channel, d_year ORDER BY net_sales DESC) AS rank_by_sales,
        SUM(net_sales) OVER (PARTITION BY channel, d_year ORDER BY d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_to_month
    FROM sales_returns_join
)
SELECT
    d_year,
    d_month_seq,
    channel,
    i_product_name,
    i_brand,
    i_category,
    i_class,
    i_manufact,
    net_sales,
    profit_amount,
    discount_amount,
    promo_cost,
    net_quantity,
    rank_by_sales,
    cumulative_sales_to_month
FROM ranked_items
WHERE rank_by_sales <= 10
ORDER BY d_year, channel, rank_by_sales
