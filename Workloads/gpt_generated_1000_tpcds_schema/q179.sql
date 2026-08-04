SELECT *
FROM (
   SELECT manufacturer_id, year
   FROM (
        SELECT i.i_manufact_id AS manufacturer_id,
               dd_sold.d_year AS year
        FROM catalog_sales cs
        JOIN date_dim dd_sold ON cs.cs_sold_date_sk = dd_sold.d_date_sk
        JOIN date_dim dd_ship ON cs.cs_ship_date_sk = dd_ship.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN store s ON s.s_closed_date_sk = dd_sold.d_date_sk
        WHERE cs.cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_units = 'Lb')
        GROUP BY GROUPING SETS (
            (i.i_manufact_id, dd_sold.d_year),
            (i.i_manufact_id),
            (dd_sold.d_year),
            ()
        )
   ) AS a
   INTERSECT
   SELECT manufacturer_id, year
   FROM (
        SELECT i.i_manufact_id AS manufacturer_id,
               dd_ret.d_year AS year
        FROM web_returns wr
        JOIN date_dim dd_ret ON wr.wr_returned_date_sk = dd_ret.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        JOIN store s2 ON s2.s_closed_date_sk = dd_ret.d_date_sk
        WHERE wr.wr_item_sk IN (SELECT i_item_sk FROM item WHERE i_units = 'Gram')
        GROUP BY GROUPING SETS (
            (i.i_manufact_id, dd_ret.d_year),
            (i.i_manufact_id),
            (dd_ret.d_year),
            ()
        )
   ) AS b
) AS intersected
ORDER BY manufacturer_id, year
LIMIT 100
