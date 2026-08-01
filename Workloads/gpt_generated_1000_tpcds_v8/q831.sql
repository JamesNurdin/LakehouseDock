WITH
    -- Date dimension aliased for different purposes
    d_sold AS (SELECT * FROM date_dim),
    d_return AS (SELECT * FROM date_dim),
    d_promo_start AS (SELECT * FROM date_dim),
    d_promo_end AS (SELECT * FROM date_dim),

    -- Aggregate catalog returns per order
    cat_ret_agg AS (
        SELECT
            cr.cr_order_number,
            cr.cr_returned_date_sk,
            SUM(cr.cr_net_loss)               AS cat_net_loss,
            COUNT(DISTINCT cr.cr_item_sk)      AS cat_distinct_items
        FROM catalog_returns cr
        GROUP BY cr.cr_order_number, cr.cr_returned_date_sk
    ),

    -- Aggregate store returns per customer and return date
    store_ret_agg AS (
        SELECT
            sr.sr_customer_sk               AS customer_sk,
            sr.sr_returned_date_sk          AS return_date_sk,
            SUM(sr.sr_net_loss)             AS store_net_loss,
            COUNT(DISTINCT sr.sr_item_sk)   AS store_distinct_items
        FROM store_returns sr
        GROUP BY sr.sr_customer_sk, sr.sr_returned_date_sk
    ),

    -- Aggregate web returns per customer and return date
    web_ret_agg AS (
        SELECT
            wr.wr_refunded_customer_sk     AS customer_sk,
            wr.wr_returned_date_sk         AS return_date_sk,
            SUM(wr.wr_net_loss)            AS web_net_loss,
            COUNT(DISTINCT wr.wr_item_sk)  AS web_distinct_items
        FROM web_returns wr
        GROUP BY wr.wr_refunded_customer_sk, wr.wr_returned_date_sk
    ),

    -- Full outer join of store and web returns to keep all unmatched rows
    full_ret AS (
        SELECT
            COALESCE(sra.customer_sk, wra.customer_sk)          AS ret_customer_sk,
            COALESCE(sra.return_date_sk, wra.return_date_sk)   AS ret_date_sk,
            sra.store_net_loss,
            wra.web_net_loss,
            sra.store_distinct_items,
            wra.web_distinct_items
        FROM store_ret_agg sra
        FULL OUTER JOIN web_ret_agg wra
            ON sra.customer_sk = wra.customer_sk
           AND sra.return_date_sk = wra.return_date_sk
    ),

    -- Main fact source joining sales and related dimensions
    base AS (
        SELECT
            d_sold.d_date                     AS sale_date,
            d_sold.d_year                     AS sale_year,
            c.c_customer_id,
            cd.cd_gender,
            p.p_promo_name,
            SUM(cs.cs_net_paid)               AS total_sales,
            COUNT(DISTINCT cs.cs_item_sk)     AS distinct_items_sold,
            /* combine net loss from catalog returns and the full outer‑joined store/web returns */
            SUM(COALESCE(cr.cat_net_loss,0) + COALESCE(fr.store_net_loss,0) + COALESCE(fr.web_net_loss,0)) AS total_net_loss,
            COUNT(DISTINCT c.c_customer_id)   AS distinct_customers,
            COUNT(DISTINCT cs.cs_item_sk)     AS distinct_items
        FROM catalog_sales cs
        JOIN d_sold               ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN promotion p          ON cs.cs_promo_sk = p.p_promo_sk
        JOIN d_promo_start        ON p.p_start_date_sk = d_promo_start.d_date_sk
        JOIN d_promo_end          ON p.p_end_date_sk   = d_promo_end.d_date_sk
        JOIN customer c           ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN cat_ret_agg cr  ON cr.cr_order_number = cs.cs_order_number
        LEFT JOIN d_return dr    ON cr.cr_returned_date_sk = dr.d_date_sk
        LEFT JOIN full_ret fr    ON fr.ret_customer_sk = c.c_customer_sk
                                 AND fr.ret_date_sk   = dr.d_date_sk
        LEFT JOIN web_sales ws   ON ws.ws_bill_customer_sk = c.c_customer_sk
                                 AND ws.ws_sold_date_sk    = d_sold.d_date_sk
        LEFT JOIN web_page wp    ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk       = ws.ws_item_sk
        WHERE NOT EXISTS (
            SELECT 1
            FROM web_sales ws2
            JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
            WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
              AND d2.d_date = DATE '2022-01-01'
        )
        GROUP BY
            d_sold.d_date,
            d_sold.d_year,
            c.c_customer_id,
            cd.cd_gender,
            p.p_promo_name
    )
SELECT
    base.sale_date,
    base.sale_year,
    base.c_customer_id,
    base.cd_gender,
    base.p_promo_name,
    base.total_sales,
    base.distinct_items_sold,
    base.total_net_loss,
    base.distinct_customers,
    base.distinct_items,
    ROW_NUMBER() OVER (PARTITION BY base.sale_year ORDER BY base.sale_date)                     AS rn_year,
    LAG(base.total_sales) OVER (PARTITION BY base.c_customer_id ORDER BY base.sale_date)       AS prev_customer_sales,
    SUM(base.total_sales) OVER (PARTITION BY base.sale_year ORDER BY base.sale_date
                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)       AS running_year_sales
FROM base
ORDER BY base.total_sales DESC
LIMIT 100
