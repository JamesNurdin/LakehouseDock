WITH yearly_avg AS (
    SELECT d.d_year,
           AVG(ss.ss_net_paid) AS avg_net_paid
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
)
SELECT
    d.d_date,
    d.d_year,
    cd.cd_gender,
    cd.cd_education_status,
    ss.ss_ticket_number,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_net_profit,
    inv.inv_quantity_on_hand,
    yr.avg_net_paid,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    CASE WHEN ss.ss_coupon_amt > 500 THEN 'High Coupon' ELSE 'Low Coupon' END AS coupon_category,
    (
        SELECT MAX(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_sold_date_sk = d.d_date_sk
    ) AS max_daily_net_paid
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN inventory inv
  ON inv.inv_date_sk = d.d_date_sk
JOIN yearly_avg yr
  ON yr.d_year = d.d_year
WHERE d.d_year = 2001
  AND cd.cd_gender = 'M'
  AND cd.cd_credit_rating = 'Low Risk'
  AND ss.ss_coupon_amt > 100
  AND ss.ss_list_price BETWEEN 10 AND 200
  AND d.d_following_holiday = 'N'
  AND ss.ss_quantity >= 1
ORDER BY profit_rank ASC, d.d_date
LIMIT 100
