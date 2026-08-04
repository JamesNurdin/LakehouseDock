WITH
    -- aggregate web returns per item and customer for later joins
    web_returns_agg AS (
        SELECT
            wr.wr_item_sk,
            wr.wr_refunded_customer_sk,
            SUM(wr.wr_net_loss) AS web_return_loss,
            SUM(wr.wr_return_amt) AS web_return_amount
        FROM web_returns wr
        GROUP BY wr.wr_item_sk, wr.wr_refunded_customer_sk
    ),
    -- aggregate catalog returns per order for later joins
    catalog_returns_agg AS (
        SELECT
            cr.cr_order_number,
            SUM(cr.cr_net_loss) AS catalog_return_loss,
            SUM(cr.cr_return_amount) AS catalog_return_amount
        FROM catalog_returns cr
        GROUP BY cr.cr_order_number
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_brand,
    SUM(ss.ss_net_profit)                                        AS total_store_net_profit,
    COALESCE(SUM(cs.cs_net_profit), 0)                           AS total_catalog_net_profit,
    COALESCE(SUM(cr_agg.catalog_return_loss), 0)                AS total_catalog_return_loss,
    COALESCE(SUM(wr_agg.web_return_loss), 0)                    AS total_web_return_loss,
    (
        SELECT COUNT(DISTINCT ss2.ss_customer_sk)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
    )                                                            AS distinct_customers,
    ROW_NUMBER() OVER (
        PARTITION BY s.s_state
        ORDER BY (
                SUM(ss.ss_net_profit) +
                COALESCE(SUM(cs.cs_net_profit), 0) -
                COALESCE(SUM(cr_agg.catalog_return_loss), 0) -
                COALESCE(SUM(wr_agg.web_return_loss), 0)
            ) DESC
    )                                                          AS profit_rank_state
FROM store_sales ss
RIGHT JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
   AND cs.cs_item_sk = i.i_item_sk
LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = i.i_item_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_returns_agg cr_agg
    ON cr_agg.cr_order_number = cr.cr_order_number
LEFT JOIN web_returns_agg wr_agg
    ON wr_agg.wr_item_sk = i.i_item_sk
   AND wr_agg.wr_refunded_customer_sk = c.c_customer_sk
WHERE
    s.s_number_employees > 200
    AND s.s_state = 'CA'
    AND s.s_rec_start_date >= DATE '2000-01-01'
    AND s.s_rec_end_date <= DATE '2001-12-31'
    AND i.i_brand = 'BrandX'
    AND i.i_rec_end_date > DATE '2002-01-01'
    AND r.r_reason_desc LIKE '%model%'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_brand,
    s.s_state,
    s.s_store_sk
ORDER BY profit_rank_state
LIMIT 100
