WITH
sales_by_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        'store' AS channel,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_ext_discount_amt) AS discount_amount,
        SUM(ss.ss_ext_tax) AS tax_amount,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_quantity) AS quantity_sold
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        'catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        SUM(cs.cs_ext_discount_amt) AS discount_amount,
        SUM(cs.cs_ext_tax) AS tax_amount,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_quantity) AS quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        SUM(ws.ws_ext_discount_amt) AS discount_amount,
        SUM(ws.ws_ext_tax) AS tax_amount,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_quantity) AS quantity_sold
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
),
returns_by_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        'store' AS channel,
        SUM(sr.sr_return_amt) AS return_amount,
        SUM(sr.sr_return_tax) AS return_tax,
        SUM(sr.sr_net_loss) AS net_loss,
        SUM(sr.sr_return_quantity) AS quantity_returned
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        'catalog' AS channel,
        SUM(cr.cr_return_amount) AS return_amount,
        SUM(cr.cr_return_tax) AS return_tax,
        SUM(cr.cr_net_loss) AS net_loss,
        SUM(cr.cr_return_quantity) AS quantity_returned
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        'web' AS channel,
        SUM(wr.wr_return_amt) AS return_amount,
        SUM(wr.wr_return_tax) AS return_tax,
        SUM(wr.wr_net_loss) AS net_loss,
        SUM(wr.wr_return_quantity) AS quantity_returned
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
),
promo_effect AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        COUNT(DISTINCT p.p_promo_id) AS promo_ids_count,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_days
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
),
final AS (
    SELECT
        s.d_year,
        s.d_month_seq,
        s.i_category,
        s.i_class,
        s.i_brand,
        s.channel,
        s.sales_amount,
        s.discount_amount,
        s.tax_amount,
        s.profit,
        s.quantity_sold,
        COALESCE(r.return_amount, 0) AS return_amount,
        COALESCE(r.return_tax, 0) AS return_tax,
        COALESCE(r.net_loss, 0) AS net_loss,
        COALESCE(r.quantity_returned, 0) AS quantity_returned,
        s.sales_amount - COALESCE(r.return_amount, 0) AS net_sales,
        s.profit - COALESCE(r.net_loss, 0) AS net_profit,
        SUM(s.sales_amount - COALESCE(r.return_amount, 0))
            OVER (PARTITION BY s.channel ORDER BY s.d_year, s.d_month_seq
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_sales,
        COALESCE(p.promo_ids_count, 0) AS promo_ids_count,
        RANK() OVER (PARTITION BY s.channel, s.d_year, s.d_month_seq
                     ORDER BY (s.sales_amount - COALESCE(r.return_amount, 0)) DESC) AS sales_rank
    FROM sales_by_month s
    LEFT JOIN returns_by_month r
        ON s.d_year = r.d_year
       AND s.d_month_seq = r.d_month_seq
       AND s.i_category = r.i_category
       AND s.i_class = r.i_class
       AND s.i_brand = r.i_brand
       AND s.channel = r.channel
    LEFT JOIN promo_effect p
        ON s.d_year = p.d_year
       AND s.d_month_seq = p.d_month_seq
       AND s.i_category = p.i_category
       AND s.i_class = p.i_class
       AND s.i_brand = p.i_brand
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    channel,
    sales_amount,
    discount_amount,
    tax_amount,
    profit,
    quantity_sold,
    return_amount,
    return_tax,
    net_loss,
    quantity_returned,
    net_sales,
    net_profit,
    running_net_sales,
    promo_ids_count,
    sales_rank
FROM final
ORDER BY d_year, d_month_seq, i_category, channel
