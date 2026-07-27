WITH joined AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        cs.cs_net_profit,
        cr.cr_net_loss,
        sr.sr_net_loss,
        wp.wp_type
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.item i
        ON i.i_item_sk = ss.ss_item_sk
        AND i.i_item_sk = cs.cs_item_sk
        AND i.i_item_sk = cr.cr_item_sk
        AND i.i_item_sk = sr.sr_item_sk
    JOIN tpcds.reason r
        ON r.r_reason_sk = cr.cr_reason_sk
        AND r.r_reason_sk = sr.sr_reason_sk
    JOIN tpcds.web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_brand_id = 10
      AND cp.cp_department = 'Sports'
      AND wp.wp_type = 'Content'
),
agg AS (
    SELECT
        d_year,
        i_category,
        i_brand,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cr_net_loss) AS total_return_loss,
        SUM(sr_net_loss) AS total_store_return_loss,
        COUNT(*) AS transaction_count
    FROM joined
    GROUP BY d_year, i_category, i_brand
    HAVING SUM(cs_net_profit) > 1000
)
SELECT
    d_year,
    i_category,
    i_brand,
    total_net_profit,
    total_return_loss,
    total_store_return_loss,
    transaction_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank,
    SUM(total_net_profit) OVER (PARTITION BY d_year) AS year_total_profit
FROM agg
ORDER BY d_year DESC, total_net_profit DESC
LIMIT 100
