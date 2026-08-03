WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        s.s_store_sk,
        s.s_store_name,
        s.s_state            AS store_state,
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        w.w_warehouse_sk,
        w.w_state            AS warehouse_state,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        CASE
            WHEN cs.cs_net_profit > 0 THEN 'POSITIVE'
            WHEN cs.cs_net_profit = 0 THEN 'ZERO'
            ELSE 'NEGATIVE'
        END                  AS profit_flag,
        (
            SELECT avg(i2.i_current_price)
            FROM tpcds.item i2
            WHERE i2.i_category = i.i_category
        )                    AS avg_category_price,
        inv.inv_quantity_on_hand,
        sr.sr_return_quantity,
        sr.sr_net_loss
    FROM tpcds.store_sales ss
    JOIN tpcds.store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.catalog_sales cs
      ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = i.i_item_sk
    WHERE w.w_state IN ('MN', 'GA')
      AND i.i_brand = 'Brand#12'
      AND ib.ib_lower_bound >= 50000
      AND cd.cd_gender = 'M'
      AND s.s_state = 'CA'
      AND inv.inv_quantity_on_hand > 0
),
agg AS (
    SELECT
        store_state,
        s_store_name,
        i_brand,
        cd_gender,
        ib_lower_bound,
        profit_flag,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_ext_sales_price) AS avg_sales,
        COUNT(*)               AS txn_count
    FROM base
    GROUP BY CUBE (store_state, s_store_name, i_brand, cd_gender, ib_lower_bound, profit_flag)
)
SELECT
    a.store_state,
    a.s_store_name,
    a.i_brand,
    a.cd_gender,
    a.ib_lower_bound,
    a.profit_flag,
    a.total_sales,
    a.avg_sales,
    a.txn_count,
    CASE
        WHEN a.total_sales > (SELECT AVG(total_sales) FROM agg) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS sales_category,
    thresh.sales_threshold
FROM agg a
CROSS JOIN (VALUES (100000), (500000)) AS thresh(sales_threshold)
WHERE a.total_sales IS NOT NULL
  AND a.txn_count > 10
ORDER BY a.total_sales DESC, a.store_state
LIMIT 100
