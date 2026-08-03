WITH filtered_cs AS (
    SELECT *
    FROM catalog_sales
    WHERE cs_quantity > 1
      AND cs_ext_sales_price > (
            SELECT MAX(cs2.cs_ext_sales_price)
            FROM catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = 20200101
      )
      AND cs_order_number NOT IN (
            SELECT ss2.ss_ticket_number
            FROM store_sales ss2
            WHERE ss2.ss_quantity > 5
      )
),
selected_p AS (
    SELECT *
    FROM promotion
    WHERE p_channel_email = 'N'
),
base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        w.w_warehouse_id,
        w.w_warehouse_sq_ft,
        p.p_promo_id,
        cd_bill.cd_gender AS bill_gender,
        hd_bill.hd_income_band_sk AS bill_income_band,
        ss.ss_ticket_number,
        ss.ss_list_price,
        ss.ss_sales_price,
        ss.ss_customer_sk,
        cd_store.cd_gender AS store_gender,
        hd_store.hd_income_band_sk AS store_income_band,
        ROW_NUMBER() OVER (ORDER BY cs.cs_net_paid DESC) AS global_row_num,
        LAG(cs.cs_net_paid) OVER (ORDER BY cs.cs_sold_date_sk) AS prev_net_paid,
        SUM(cs.cs_ext_sales_price) OVER (
            PARTITION BY w.w_warehouse_id
            ORDER BY cs.cs_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_sales_by_wh
    FROM filtered_cs cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN selected_p p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd_store
        ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    JOIN household_demographics hd_store
        ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
    WHERE ss.ss_list_price > 100
      AND w.w_warehouse_sq_ft > 5000
)
SELECT
    w_warehouse_id,
    w_warehouse_sq_ft,
    COUNT(DISTINCT cs_item_sk) AS distinct_items_sold,
    COUNT(DISTINCT ss_customer_sk) AS distinct_store_customers,
    MAX(global_row_num) AS max_global_row_num,
    MAX(running_sales_by_wh) AS total_sales_by_warehouse
FROM base
GROUP BY w_warehouse_id, w_warehouse_sq_ft
ORDER BY total_sales_by_warehouse DESC
LIMIT 100
