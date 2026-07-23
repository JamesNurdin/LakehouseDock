WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_ticket_number,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        SUM(ss_quantity) AS total_qty_sold,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        AVG(ss_sales_price) AS avg_sales_price
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2452000
      AND ss_sales_price > 5.00
    GROUP BY ss_item_sk, ss_ticket_number, ss_customer_sk, ss_cdemo_sk, ss_hdemo_sk
),
final_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        cc.cc_call_center_id,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_vehicle_count,
        ib.ib_income_band_sk,
        SUM(ss_agg.total_qty_sold) AS total_quantity_sold,
        SUM(ss_agg.total_sales) AS total_sales_amount,
        SUM(ss_agg.total_profit) AS total_profit_amount,
        CASE WHEN SUM(ss_agg.total_profit) > 5000 THEN 'High' ELSE 'Low' END AS profit_category,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_ticket_count,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount
    FROM ss_agg
    JOIN item i
        ON ss_agg.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss_agg.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss_agg.ss_ticket_number
        AND sr.sr_item_sk = ss_agg.ss_item_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_tax_percentage > 5.0
      AND cc.cc_gmt_offset BETWEEN -5.00 AND 0.00
      AND i.i_current_price BETWEEN 20 AND 200
      AND i.i_color = 'Red'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_lower_bound >= 30000
      AND cd.cd_gender = 'M'
      AND c.c_salutation = 'Mr.'
      AND c.c_first_shipto_date_sk = 2449406
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
    GROUP BY i.i_item_id,
             i.i_product_name,
             i.i_brand,
             i.i_category,
             cc.cc_call_center_id,
             c.c_customer_id,
             cd.cd_gender,
             hd.hd_vehicle_count,
             ib.ib_income_band_sk
    HAVING SUM(ss_agg.total_profit) > 1000
)
SELECT
    final_agg.i_item_id,
    final_agg.i_product_name,
    final_agg.i_brand,
    final_agg.i_category,
    final_agg.cc_call_center_id,
    final_agg.c_customer_id,
    final_agg.cd_gender,
    final_agg.hd_vehicle_count,
    final_agg.ib_income_band_sk,
    final_agg.total_quantity_sold,
    final_agg.total_sales_amount,
    final_agg.total_profit_amount,
    final_agg.profit_category,
    final_agg.return_ticket_count,
    final_agg.total_return_amount,
    final_agg.total_catalog_return_amount,
    ROW_NUMBER() OVER (PARTITION BY final_agg.ib_income_band_sk ORDER BY final_agg.total_profit_amount DESC) AS profit_rank_within_income_band
FROM final_agg
ORDER BY final_agg.total_profit_amount DESC
LIMIT 100
