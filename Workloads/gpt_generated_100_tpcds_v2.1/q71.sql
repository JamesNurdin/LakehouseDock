WITH returns_per_item_reason AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        r.r_reason_desc,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        SUM(sr.sr_return_amt) AS store_return_amt,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS web_return_qty,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_amt
    FROM
        store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d_sr.d_date_sk
        LEFT JOIN web_returns wr
            ON wr.wr_item_sk = i.i_item_sk
            AND wr.wr_returned_date_sk = d_sr.d_date_sk
        LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN customer_demographics cd_wr ON wr.wr_returning_cdemo_sk = cd_wr.cd_demo_sk
        LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE
        d_sr.d_year = 2001
        AND s.s_state = 'CA'
        AND i.i_brand_id = 10
        AND r.r_reason_desc = 'duplicate purchase'
        AND d_sr.d_holiday = 'N'
        AND d_sr.d_weekend = 'N'
        AND i.i_color = 'red'
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        r.r_reason_desc
),
avg_profit_per_item AS (
    SELECT
        cs.cs_item_sk,
        AVG(cs.cs_net_profit) AS avg_net_profit
    FROM
        catalog_sales cs
        JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        d_cs.d_year = 2001
        AND cc.cc_state = 'CA'
        AND sm.sm_type = 'AIR'
        AND cs.cs_quantity > 0
    GROUP BY
        cs.cs_item_sk
)
SELECT
    rpi.i_item_id,
    rpi.i_item_desc,
    SUM(rpi.store_return_qty) AS total_store_return_qty,
    SUM(rpi.store_return_amt) AS total_store_return_amt,
    SUM(rpi.web_return_qty) AS total_web_return_qty,
    SUM(rpi.web_return_amt) AS total_web_return_amt,
    ap.avg_net_profit
FROM
    returns_per_item_reason rpi
    LEFT JOIN avg_profit_per_item ap ON rpi.i_item_sk = ap.cs_item_sk
WHERE
    EXISTS (
        SELECT 1
        FROM catalog_sales cs_check
        WHERE cs_check.cs_item_sk = rpi.i_item_sk
          AND cs_check.cs_net_paid > 1000
    )
GROUP BY
    rpi.i_item_id,
    rpi.i_item_desc,
    ap.avg_net_profit
HAVING
    SUM(rpi.store_return_amt) > 1000
ORDER BY
    total_store_return_amt DESC
LIMIT 10
