WITH sales_summary AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_item_sk,
        i.i_product_name,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE td.t_hour BETWEEN 9 AND 17                                   -- business hours
      AND s.s_state = 'CA'                                             -- store in California
      AND i.i_brand = 'BrandA'                                          -- specific brand
      AND p.p_channel_press = 'N'                                       -- press channel not used
      AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
              AND p2.p_discount_active = 'Y'
              AND p2.p_channel_email = 'N'
            LIMIT 1
        )                                                            -- at least one active discount promotion
    GROUP BY ss.ss_store_sk, s.s_store_name, ss.ss_item_sk, i.i_product_name
),
store_return_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS return_qty
    FROM store_returns sr
    JOIN time_dim td2
        ON sr.sr_return_time_sk = td2.t_time_sk
    WHERE td2.t_hour BETWEEN 9 AND 17
    GROUP BY sr.sr_store_sk, sr.sr_item_sk
),
catalog_return_agg AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS return_qty
    FROM catalog_returns cr
    JOIN time_dim td3
        ON cr.cr_returned_time_sk = td3.t_time_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE td3.t_hour BETWEEN 9 AND 17
      AND cp.cp_department = 'Electronics'           -- filter department
      AND cp.cp_catalog_number IN (11, 15)           -- specific catalog numbers
    GROUP BY cr.cr_item_sk
),
web_return_agg AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS return_qty
    FROM web_returns wr
    JOIN time_dim td4
        ON wr.wr_returned_time_sk = td4.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE td4.t_hour BETWEEN 9 AND 17
      AND wp.wp_type = 'article'                     -- only article pages
    GROUP BY wr.wr_item_sk
)
SELECT
    ss.ss_store_sk,
    ss.s_store_name,
    ss.i_product_name,
    ss.sales_amount,
    ss.profit_amount,
    COALESCE(sr.return_qty, 0) AS store_return_qty,
    COALESCE(cr.return_qty, 0) AS catalog_return_qty,
    COALESCE(wr.return_qty, 0) AS web_return_qty,
    (
        SELECT COUNT(DISTINCT p3.p_promo_sk)
        FROM promotion p3
        WHERE p3.p_item_sk = ss.ss_item_sk
    ) AS promo_count,
    ROW_NUMBER() OVER (PARTITION BY ss.s_store_name ORDER BY ss.profit_amount DESC) AS profit_rank
FROM sales_summary ss
LEFT JOIN store_return_agg sr
    ON ss.ss_store_sk = sr.sr_store_sk AND ss.ss_item_sk = sr.sr_item_sk
LEFT JOIN catalog_return_agg cr
    ON ss.ss_item_sk = cr.cr_item_sk
LEFT JOIN web_return_agg wr
    ON ss.ss_item_sk = wr.wr_item_sk
WHERE ss.sales_amount > 1000                                            -- meaningful sales threshold
ORDER BY ss.profit_amount DESC
LIMIT 100
