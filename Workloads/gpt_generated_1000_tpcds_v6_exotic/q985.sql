WITH joined_all AS (
    SELECT
        d.d_year,
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_manager_id,
        i.i_class_id,
        i.i_wholesale_cost,
        i.i_current_price,
        cs.cs_net_paid,
        cs.cs_quantity,
        ws.ws_net_paid,
        ws.ws_quantity,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cc.cc_name,
        sm.sm_type,
        s.s_country,
        r.r_reason_desc,
        ca.ca_state,
        cd.cd_gender
    FROM
        date_dim d
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON i.i_item_sk = cs.cs_item_sk
        LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
            AND cr.cr_item_sk = i.i_item_sk
            AND cr.cr_order_number = cs.cs_order_number
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_item_sk = i.i_item_sk
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
            AND wr.wr_item_sk = i.i_item_sk
            AND wr.wr_order_number = ws.ws_order_number
        LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
            AND sr.sr_item_sk = i.i_item_sk
        LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON (p.p_start_date_sk = d.d_date_sk OR p.p_end_date_sk = d.d_date_sk)
            AND p.p_item_sk = i.i_item_sk
        LEFT JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
        LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
        LEFT JOIN store s ON s.s_store_sk = sr.sr_store_sk
        LEFT JOIN reason r ON r.r_reason_sk = COALESCE(cr.cr_reason_sk, sr.sr_reason_sk, wr.wr_reason_sk)
        LEFT JOIN customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
        LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    WHERE
        i.i_manager_id IN (6, 18)
        AND i.i_class_id = 15
        AND i.i_wholesale_cost > 10
        AND s.s_country = 'United States'
        AND d.d_year BETWEEN 2000 AND 2002
        AND cs.cs_quantity > 5
),
agg_item_year AS (
    SELECT
        i_item_id,
        i_item_desc,
        d_year,
        SUM(cs_net_paid) AS total_catalog_sales,
        SUM(ws_net_paid) AS total_web_sales,
        SUM(sr_net_loss) AS total_store_return_loss,
        SUM(cr_return_amount) AS total_catalog_returns,
        COUNT(DISTINCT cs_net_paid) AS catalog_records
    FROM joined_all
    GROUP BY i_item_id, i_item_desc, d_year
)
SELECT
    aiy.i_item_id,
    aiy.i_item_desc,
    aiy.d_year,
    aiy.total_catalog_sales,
    aiy.total_web_sales,
    aiy.total_store_return_loss,
    aiy.total_catalog_returns,
    (aiy.total_catalog_sales + aiy.total_web_sales) AS total_sales,
    AVG(a.i_wholesale_cost) OVER (PARTITION BY aiy.d_year) AS avg_wholesale_cost_year,
    RANK() OVER (PARTITION BY aiy.d_year ORDER BY (aiy.total_catalog_sales + aiy.total_web_sales) DESC) AS sales_rank
FROM
    agg_item_year aiy
    JOIN joined_all a ON a.i_item_id = aiy.i_item_id AND a.d_year = aiy.d_year
WHERE
    EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = a.i_item_sk
          AND p2.p_discount_active = 'Y'
    )
    AND a.i_current_price > (
        SELECT AVG(i3.i_current_price) FROM item i3 WHERE i3.i_brand_id = 1
    )
    AND (aiy.total_catalog_sales + aiy.total_web_sales) > 10000
ORDER BY
    aiy.d_year,
    sales_rank
LIMIT 100
