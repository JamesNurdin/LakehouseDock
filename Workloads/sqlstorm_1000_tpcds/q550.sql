WITH
sales AS (
    SELECT
        d.d_date AS sale_date,
        'catalog' AS channel,
        cs.cs_item_sk AS item_sk,
        i.i_product_name AS product_name,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS profit,
        cs.cs_ext_discount_amt AS discount,
        p.p_promo_name AS promo_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
),
store_sales_cte AS (
    SELECT
        d.d_date AS sale_date,
        'store' AS channel,
        ss.ss_item_sk AS item_sk,
        i.i_product_name AS product_name,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS profit,
        ss.ss_ext_discount_amt AS discount,
        p.p_promo_name AS promo_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
),
web_sales_cte AS (
    SELECT
        d.d_date AS sale_date,
        'web' AS channel,
        ws.ws_item_sk AS item_sk,
        i.i_product_name AS product_name,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS profit,
        ws.ws_ext_discount_amt AS discount,
        p.p_promo_name AS promo_name
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
),
returns AS (
    SELECT
        d.d_date AS return_date,
        'catalog' AS channel,
        cr.cr_item_sk AS item_sk,
        i.i_product_name AS product_name,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amt_inc_tax AS return_amount,
        cr.cr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        d.d_date AS return_date,
        'store' AS channel,
        sr.sr_item_sk AS item_sk,
        i.i_product_name AS product_name,
        sr.sr_return_quantity AS quantity,
        sr.sr_return_amt_inc_tax AS return_amount,
        sr.sr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        d.d_date AS return_date,
        'web' AS channel,
        wr.wr_item_sk AS item_sk,
        i.i_product_name AS product_name,
        wr.wr_return_quantity AS quantity,
        wr.wr_return_amt_inc_tax AS return_amount,
        wr.wr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
),
combined AS (
    SELECT
        s.sale_date,
        s.channel,
        s.item_sk,
        s.product_name,
        s.quantity AS sold_quantity,
        s.net_paid AS total_sales,
        s.profit AS total_profit,
        s.discount AS total_discount,
        COALESCE(s.promo_name, 'N/A') AS promo_name,
        COALESCE(r.return_amount, 0) AS total_returns_amount,
        COALESCE(r.net_loss, 0) AS total_returns_loss,
        COALESCE(r.quantity, 0) AS return_quantity,
        COALESCE(r.reason_desc, 'No Reason') AS return_reason
    FROM (
        SELECT * FROM sales
        UNION ALL
        SELECT * FROM store_sales_cte
        UNION ALL
        SELECT * FROM web_sales_cte
    ) s
    LEFT JOIN returns r
        ON s.sale_date = r.return_date
        AND s.item_sk = r.item_sk
        AND s.channel = r.channel
),
ranked AS (
    SELECT
        c.sale_date,
        c.channel,
        c.item_sk,
        c.product_name,
        c.sold_quantity,
        c.total_sales,
        c.total_profit,
        c.total_discount,
        c.promo_name,
        c.total_returns_amount,
        c.total_returns_loss,
        c.return_quantity,
        c.return_reason,
        DATE_TRUNC('month', c.sale_date) AS month_start,
        SUM(c.total_profit - c.total_returns_loss)
            OVER (PARTITION BY c.channel ORDER BY c.sale_date
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
        RANK() OVER (PARTITION BY c.channel, DATE_TRUNC('month', c.sale_date)
                     ORDER BY c.total_profit - c.total_returns_loss DESC) AS product_month_rank,
        CONCAT(c.channel, '_', CAST(c.item_sk AS VARCHAR)) AS composite_key
    FROM combined c
    WHERE (c.total_sales IS NOT NULL AND c.total_sales > 0) OR c.total_returns_amount > 0
),
final AS (
    SELECT
        r.sale_date,
        r.channel,
        r.product_name,
        r.sold_quantity,
        r.total_sales,
        r.total_profit,
        r.total_discount,
        r.promo_name,
        r.total_returns_amount,
        r.total_returns_loss,
        r.return_quantity,
        r.return_reason,
        r.cumulative_profit,
        r.product_month_rank,
        r.composite_key,
        CASE
            WHEN r.total_profit - r.total_returns_loss > 0 THEN 'Profit'
            WHEN r.total_profit - r.total_returns_loss < 0 THEN 'Loss'
            ELSE 'Break-even'
        END AS profit_status,
        COALESCE(NULLIF(r.return_reason, ''), 'Unknown') AS cleaned_return_reason,
        (SELECT MAX(c2.total_returns_amount)
         FROM combined c2
         WHERE c2.item_sk = r.item_sk
           AND c2.channel = r.channel) AS max_return_amount_for_product
    FROM ranked r
    WHERE r.product_month_rank <= 5
)
SELECT *
FROM final
ORDER BY channel, sale_date, product_month_rank
LIMIT 100
