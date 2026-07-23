WITH item_aggregates AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        cc.cc_name,
        cc.cc_state,
        cp.cp_catalog_page_number,
        d_sales.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_net_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_net_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_ticket_cnt
    FROM item i
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales
        ON ss.ss_sold_time_sk = t_sales.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN customer_demographics cd_sales
        ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
    LEFT JOIN customer_demographics cd_cr_refunded
        ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
    LEFT JOIN customer_demographics cd_wr_refunded
        ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    WHERE d_sales.d_year = 2001
      AND i.i_category = 'Electronics'
      AND cc.cc_state IN ('CA', 'TX')
      AND cp.cp_catalog_page_number BETWEEN 5 AND 20
      AND t_sales.t_hour BETWEEN 9 AND 17
      AND d_sales.d_holiday = 'N'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        cc.cc_name,
        cc.cc_state,
        cp.cp_catalog_page_number,
        d_sales.d_year
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    ia.i_item_id,
    ia.i_product_name,
    ia.i_category,
    ia.i_brand,
    ia.cc_name,
    ia.cc_state,
    ia.cp_catalog_page_number,
    ia.d_year,
    ia.total_sales,
    ia.catalog_net_loss,
    ia.web_net_loss,
    ia.distinct_ticket_cnt,
    (ia.catalog_net_loss + ia.web_net_loss) AS total_net_loss,
    RANK() OVER (PARTITION BY ia.cc_state ORDER BY (ia.catalog_net_loss + ia.web_net_loss) DESC) AS loss_rank_state,
    CASE
        WHEN (ia.catalog_net_loss + ia.web_net_loss) > 5000 THEN 'High Loss'
        WHEN (ia.catalog_net_loss + ia.web_net_loss) > 2000 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category,
    (
        SELECT COUNT(DISTINCT ss2.ss_ticket_number)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
          AND ss2.ss_sold_date_sk = (
              SELECT d2.d_date_sk
              FROM date_dim d2
              WHERE d2.d_year = 2001
              LIMIT 1
          )
    ) AS distinct_ticket_cnt_2001
FROM item_aggregates ia
JOIN item i
    ON i.i_item_id = ia.i_item_id
ORDER BY ia.cc_state, loss_rank_state, ia.total_sales DESC
LIMIT 100
