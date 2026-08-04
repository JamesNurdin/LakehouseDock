WITH intersect_orders AS ( 
    SELECT cs_order_number AS order_number
    FROM catalog_sales
    INTERSECT
    SELECT ws_order_number
    FROM web_sales
),
base AS ( 
    SELECT 
        cs.cs_order_number,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        r.r_reason_desc,
        sm.sm_type,
        w.w_state,
        ib.ib_lower_bound,
        cd.cd_gender,
        hd.hd_buy_potential,
        we.web_country
    FROM catalog_sales cs
    JOIN intersect_orders io ON cs.cs_order_number = io.order_number
    JOIN catalog_returns cr 
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer_demographics cd 
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd 
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib 
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm 
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w 
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN reason r 
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr 
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
       AND sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN "store" s 
        ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws 
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
       AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr 
        ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site we 
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '5001-10000'
      AND ib.ib_lower_bound >= 5000
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND s.s_market_manager = 'John Miller'
      AND r.r_reason_desc LIKE '%product%'
),
agg AS ( 
    SELECT 
        r_reason_desc,
        SUM(cr_return_amount) AS cat_return_sum,
        SUM(sr_return_amt) AS store_return_sum,
        SUM(wr_return_amt) AS web_return_sum,
        SUM(cr_return_amount + sr_return_amt + wr_return_amt) AS total_return
    FROM base
    GROUP BY r_reason_desc
),
first_select AS ( 
    SELECT r_reason_desc, total_return
    FROM agg
    WHERE total_return > 0
),
second_select AS ( 
    SELECT r_reason_desc, total_return
    FROM agg
    WHERE total_return >= 1000
),
unioned AS ( 
    SELECT * FROM first_select
    UNION
    SELECT * FROM second_select
)
SELECT 
    r_reason_desc,
    total_return,
    ROW_NUMBER() OVER (ORDER BY total_return DESC) AS rn
FROM unioned
ORDER BY total_return DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
